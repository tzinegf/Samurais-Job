import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_request_model.dart';
import '../auth/auth_controller.dart';

class ProfessionalController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxList<ServiceRequestModel> _allPendingRequests = <ServiceRequestModel>[].obs;
  RxList<ServiceRequestModel> availableRequests = <ServiceRequestModel>[].obs;
  RxList<ServiceRequestModel> myRequests = <ServiceRequestModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Setup listeners for filtering
    ever(_authController.currentUser, (_) => _filterRequests());
    ever(_allPendingRequests, (_) => _filterRequests());

    fetchAvailableRequests();
    fetchMyRequests();
  }

  void _filterRequests() {
    final user = _authController.currentUser.value;
    final skills = user?.skills ?? [];

    if (skills.isNotEmpty) {
      availableRequests.value = _allPendingRequests.where((req) {
        // Case insensitive and trim check
        return skills.any(
          (skill) =>
              skill.toLowerCase().trim() == req.category.toLowerCase().trim(),
        );
      }).toList();
    } else {
      // Fallback: Show all if no skills defined (or show empty if you prefer strict mode)
      availableRequests.value = _allPendingRequests.toList();
    }
  }

  void fetchAvailableRequests() {
    // Realtime listener for pending requests
    _db
        .collection('service_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (snapshot) {
            _allPendingRequests.value = snapshot.docs
                .map((doc) => ServiceRequestModel.fromDocument(doc))
                .toList();
          },
          onError: (e) {
            Get.snackbar("Erro", "Falha ao carregar pedidos: $e");
          },
        );
  }

  void fetchMyRequests() {
    String? uid = _authController.firebaseUser.value?.uid;
    if (uid == null) return;

    _db
        .collection('service_requests')
        .where('professionalId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          myRequests.value = snapshot.docs
              .map((doc) => ServiceRequestModel.fromDocument(doc))
              .toList();
        });
  }

  static const int ACCEPT_COST = 20;

  Future<void> acceptRequest(ServiceRequestModel request) async {
    try {
      isLoading.value = true;
      final currentUser = _authController.currentUser.value;

      if (currentUser == null) {
        Get.snackbar('Erro', 'Usuário não identificado.');
        return;
      }

      // Check limit of 3 accepted services per category
      final activeRequestsInSameCategory = myRequests
          .where(
            (r) => r.status == 'accepted' && r.category == request.category,
          )
          .length;

      if (activeRequestsInSameCategory >= 3) {
        Get.snackbar(
          'Limite Atingido',
          'Você já possui 3 serviços em andamento na categoria ${request.category}. Finalize um para aceitar novos.',
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
        );
        return;
      }

      if ((currentUser.coins ?? 0) < ACCEPT_COST) {
        Get.snackbar(
          'Saldo Insuficiente',
          'Você precisa de $ACCEPT_COST moedas para aceitar este pedido. Seu saldo: ${currentUser.coins ?? 0}',
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
        );
        return;
      }

      // Deduct coins and update request in a transaction or batch
      final userRef = _db.collection('users').doc(currentUser.id);
      final requestRef = _db.collection('service_requests').doc(request.id);

      await _db.runTransaction((transaction) async {
        // Double check balance inside transaction
        final userSnapshot = await transaction.get(userRef);
        final currentCoins = userSnapshot.data()?['coins'] ?? 0;

        if (currentCoins < ACCEPT_COST) {
          throw Exception("Saldo insuficiente no momento da transação.");
        }

        // Deduct coins
        transaction.update(userRef, {'coins': currentCoins - ACCEPT_COST});

        // Update request
        transaction.update(requestRef, {
          'status': 'accepted',
          'professionalId': currentUser.id,
        });
      });

      // Update local user state immediately for UI responsiveness
      currentUser.coins = (currentUser.coins ?? 0) - ACCEPT_COST;
      _authController.currentUser.refresh();

      Get.snackbar(
        'Sucesso',
        'Pedido aceito! $ACCEPT_COST moedas descontadas.',
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao aceitar pedido: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCoins(int amount) async {
    try {
      final user = _authController.currentUser.value;
      if (user == null) return;

      await _db.collection('users').doc(user.id).update({
        'coins': FieldValue.increment(amount),
      });

      // Local update
      user.coins = (user.coins ?? 0) + amount;
      _authController.currentUser.refresh();

      Get.snackbar('Moedas Adicionadas', 'Você recebeu $amount moedas!');
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao adicionar moedas: $e');
    }
  }

  Future<void> simulatePurchase(int coins, double price) async {
    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Simulate network delay
      await Future.delayed(Duration(seconds: 2));

      Get.back(); // Close loading

      // Here we would integrate with Mercado Pago
      // For now, we assume success
      await addCoins(coins);

      Get.snackbar(
        'Compra Realizada',
        'Pagamento de R\$ ${price.toStringAsFixed(2)} confirmado!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } catch (e) {
      Get.back(); // Close loading if error
      Get.snackbar('Erro', 'Falha no pagamento: $e');
    }
  }

  void finishRequest({
    required String requestId,
    required double clientRating,
    required String clientReview,
    required bool professionalHasProblem,
    String? professionalProblemDescription,
  }) async {
    try {
      isLoading.value = true;

      final request = myRequests.firstWhere((r) => r.id == requestId);
      final clientId = request.clientId;

      await _db.runTransaction((transaction) async {
        final requestRef = _db.collection('service_requests').doc(requestId);

        // Update Service Request
        transaction.update(requestRef, {
          'status':
              'completed', // Or keep 'completed' if already set? Let's ensure it's completed.
          'completedAt': FieldValue.serverTimestamp(),
          'clientRating': clientRating,
          'clientReview': clientReview,
          'professionalHasProblem': professionalHasProblem,
          'professionalProblemDescription': professionalProblemDescription,
        });

        // Update Client's Rating
        final clientRef = _db.collection('users').doc(clientId);
        final clientDoc = await transaction.get(clientRef);

        if (clientDoc.exists) {
          final data = clientDoc.data() as Map<String, dynamic>;
          final currentRating = (data['rating'] is int)
              ? (data['rating'] as int).toDouble()
              : (data['rating'] ?? 0.0).toDouble();
          final currentCount = data['ratingCount'] ?? 0;

          final newCount = currentCount + 1;
          final newRating =
              ((currentRating * currentCount) + clientRating) / newCount;

          transaction.update(clientRef, {
            'rating': newRating,
            'ratingCount': newCount,
          });
        }
      });

      Get.back(); // Close dialog
      Get.back(); // Close details bottom sheet
      Get.snackbar(
        "Sucesso",
        "Serviço finalizado e cliente avaliado com sucesso!",
      );
    } catch (e) {
      Get.snackbar("Erro ao finalizar serviço", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Temporary helper to create a dummy request for testing
  Future<void> createDummyRequest() async {
    var request = ServiceRequestModel(
      clientId: 'dummy_client_id',
      title: 'Reparo de Encanamento',
      description: 'Vazamento na pia da cozinha',
      category: 'Encanador',
      price: 150.0,
    );
    await _db.collection('service_requests').add(request.toJson());
  }
}
