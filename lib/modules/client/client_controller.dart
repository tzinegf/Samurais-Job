import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/service_request_model.dart';
import '../auth/auth_controller.dart';

class ClientController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  RxString selectedCategory = ''.obs;
  Rx<LatLng?> selectedLocation = Rx<LatLng?>(null); // New location field
  RxList<ServiceRequestModel> myRequests = <ServiceRequestModel>[].obs;
  RxBool isLoading = false.obs;

  final List<String> categories = [
    'Marceneiro',
    'Encanador',
    'Pedreiro',
    'Eletricista',
    'Pintor',
    'Jardinagem',
    'Limpeza',
    'Mecânico',
    'Informática',
    'Montador de Móveis',
    'Costureira',
    'Cozinheiro',
  ];

  @override
  void onInit() {
    super.onInit();
    selectedCategory.value = categories.first;

    // Listen to auth changes to start fetching requests when user is ready
    ever(_authController.firebaseUser, (_) => fetchMyRequests());
    fetchMyRequests(); // Try initial fetch
  }

  void fetchMyRequests() {
    String? uid = _authController.firebaseUser.value?.uid;
    if (uid == null) return;

    _db
        .collection('service_requests')
        .where('clientId', isEqualTo: uid)
        // .orderBy('createdAt', descending: true) // Temporarily removed to check index issue
        .snapshots()
        .listen(
          (snapshot) {
            myRequests.value = snapshot.docs
                .map((doc) => ServiceRequestModel.fromDocument(doc))
                .toList();
            // Sort locally as fallback
            myRequests.sort(
              (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                a.createdAt ?? DateTime.now(),
              ),
            );
          },
          onError: (e) {
            print("Error fetching requests: $e");
            Get.snackbar("Erro", "Falha ao carregar pedidos: $e");
          },
        );
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Erro', 'Serviços de localização desativados.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Erro', 'Permissão de localização negada.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Erro',
          'Permissões de localização permanentemente negadas. Não podemos solicitar permissões.');
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      isLoading.value = true;
      Position position = await Geolocator.getCurrentPosition();
      selectedLocation.value = LatLng(position.latitude, position.longitude);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao obter localização: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void createRequest() async {
    if (titleCtrl.text.isEmpty || descriptionCtrl.text.isEmpty) {
      Get.snackbar("Erro", "Preencha título e descrição.");
      return;
    }

    try {
      isLoading.value = true;
      String? uid = _authController.firebaseUser.value?.uid;
      if (uid == null) {
        Get.snackbar("Erro", "Usuário não identificado.");
        return;
      }

      double? price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));

      ServiceRequestModel newRequest = ServiceRequestModel(
        clientId: uid,
        title: titleCtrl.text.trim(),
        description: descriptionCtrl.text.trim(),
        category: selectedCategory.value,
        price: price,
        status: 'pending',
        latitude: selectedLocation.value?.latitude,
        longitude: selectedLocation.value?.longitude,
      );

      await _db.collection('service_requests').add(newRequest.toJson());

      Get.back(); // Close dialog
      Get.snackbar("Sucesso", "Solicitação criada com sucesso!");

      // Clear fields
      titleCtrl.clear();
      descriptionCtrl.clear();
      priceCtrl.clear();
      selectedLocation.value = null;
    } catch (e) {
      Get.snackbar("Erro ao criar solicitação", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void updateRequest(String requestId) async {
    if (titleCtrl.text.isEmpty || descriptionCtrl.text.isEmpty) {
      Get.snackbar("Erro", "Preencha título e descrição.");
      return;
    }

    try {
      isLoading.value = true;
      double? price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));

      Map<String, dynamic> data = {
        'title': titleCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'category': selectedCategory.value,
        'price': price,
      };

      await _db.collection('service_requests').doc(requestId).update(data);

      Get.back(); // Close dialog
      Get.back(); // Close details bottom sheet if open (optional, depending on flow)
      Get.snackbar("Sucesso", "Solicitação atualizada com sucesso!");

      // Clear fields
      titleCtrl.clear();
      descriptionCtrl.clear();
      priceCtrl.clear();
    } catch (e) {
      Get.snackbar("Erro ao atualizar solicitação", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void deleteRequest(String requestId) async {
    try {
      isLoading.value = true;
      await _db.collection('service_requests').doc(requestId).delete();
      Get.back(); // Close details bottom sheet
      Get.snackbar("Sucesso", "Solicitação excluída com sucesso!");
    } catch (e) {
      Get.snackbar("Erro ao excluir solicitação", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void finishRequest({
    required String requestId,
    required double rating,
    required String review,
    required bool hasProblem,
    String? problemDescription,
  }) async {
    try {
      isLoading.value = true;

      final request = myRequests.firstWhere((r) => r.id == requestId);
      final professionalId = request.professionalId;

      await _db.runTransaction((transaction) async {
        final requestRef = _db.collection('service_requests').doc(requestId);

        // Update Service Request
        transaction.update(requestRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'rating': rating,
          'review': review,
          'hasProblem': hasProblem,
          'problemDescription': problemDescription,
        });

        // Update Professional's Rating
        if (professionalId != null) {
          final professionalRef = _db.collection('users').doc(professionalId);
          final professionalDoc = await transaction.get(professionalRef);

          if (professionalDoc.exists) {
            final data = professionalDoc.data() as Map<String, dynamic>;
            final currentRating = (data['rating'] is int)
                ? (data['rating'] as int).toDouble()
                : (data['rating'] ?? 0.0).toDouble();
            final currentCount = data['ratingCount'] ?? 0;

            final newCount = currentCount + 1;
            final newRating =
                ((currentRating * currentCount) + rating) / newCount;

            transaction.update(professionalRef, {
              'rating': newRating,
              'ratingCount': newCount,
            });
          }
        }
      });

      Get.back(); // Close dialog
      Get.back(); // Close details bottom sheet
      Get.snackbar("Sucesso", "Serviço finalizado e avaliado com sucesso!");
    } catch (e) {
      Get.snackbar("Erro ao finalizar serviço", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getProfessionalDetails(
    String professionalId,
  ) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(professionalId)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Erro ao buscar profissional: $e");
    }
    return null;
  }
}
