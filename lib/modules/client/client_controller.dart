import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_request_model.dart';
import '../auth/auth_controller.dart';

class ClientController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  RxString selectedCategory = ''.obs;
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
      );

      await _db.collection('service_requests').add(newRequest.toJson());

      Get.back(); // Close dialog
      Get.snackbar("Sucesso", "Solicitação criada com sucesso!");

      // Clear fields
      titleCtrl.clear();
      descriptionCtrl.clear();
      priceCtrl.clear();
      selectedCategory.value = categories.first;
    } catch (e) {
      Get.snackbar("Erro", "Erro ao criar solicitação: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
