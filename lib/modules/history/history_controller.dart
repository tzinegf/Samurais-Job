import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_request_model.dart';
import '../auth/auth_controller.dart';

class HistoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  RxList<ServiceRequestModel> historyRequests = <ServiceRequestModel>[].obs;
  
  // Categorized lists
  RxList<ServiceRequestModel> completedRequests = <ServiceRequestModel>[].obs;
  RxList<ServiceRequestModel> refusedRequests = <ServiceRequestModel>[].obs;
  RxList<ServiceRequestModel> cancelledRequests = <ServiceRequestModel>[].obs;

  RxBool isLoading = false.obs;

  StreamSubscription? _historySubscription;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  @override
  void onClose() {
    _historySubscription?.cancel();
    super.onClose();
  }

  void fetchHistory() {
    isLoading.value = true;
    try {
      final user = _authController.currentUser.value;
      if (user == null) {
        if (_authController.firebaseUser.value != null) {
          // Retry logic could be added here
        }
        isLoading.value = false;
        return;
      }

      Query query = _db.collection('service_requests');

      if (user.role == 'professional') {
        // Fetch all requests where I was involved (sent a quote)
        query = query.where('quotedBy', arrayContains: user.id);
      } else {
        // Client logic (kept for compatibility, though this controller seems professional-focused)
        query = query.where('clientId', isEqualTo: user.id);
      }

      // Filter for non-pending statuses
      query = query.where('status', whereIn: ['accepted', 'completed', 'cancelled']);

      _historySubscription = query.snapshots().listen(
        (snapshot) {
          final requests = snapshot.docs
              .map((doc) => ServiceRequestModel.fromDocument(doc))
              .toList();

          // Sort locally by date desc
          requests.sort((a, b) {
            final aDate = a.createdAt ?? DateTime(0);
            final bDate = b.createdAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });

          historyRequests.assignAll(requests);
          _categorizeRequests(requests, user.id ?? '');
          
          isLoading.value = false;
        },
        onError: (e) {
          print("Error fetching history: $e");
          Get.snackbar(
            "Erro",
            "Não foi possível carregar o histórico.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          isLoading.value = false;
        },
      );
    } catch (e) {
      print("Error setting up history listener: $e");
      isLoading.value = false;
    }
  }

  void _categorizeRequests(List<ServiceRequestModel> requests, String userId) {
    final completed = <ServiceRequestModel>[];
    final refused = <ServiceRequestModel>[];
    final cancelled = <ServiceRequestModel>[];

    for (var req in requests) {
      if (req.professionalId == userId) {
        // I was the chosen professional
        if (req.status == 'completed') {
          completed.add(req);
        } else if (req.status == 'cancelled') {
          cancelled.add(req);
        }
        // 'accepted' is active, handled in Dashboard, not History
      } else {
        // I was NOT the chosen professional (but I quoted)
        // This means I was refused/not selected
        // Even if status is 'accepted' (active for someone else) or 'cancelled' (cancelled before or after selection of someone else)
        // or 'completed' (by someone else).
        // Essentially, if I am not the pro, it's a "Recusado" for me.
        refused.add(req);
      }
    }

    completedRequests.assignAll(completed);
    refusedRequests.assignAll(refused);
    cancelledRequests.assignAll(cancelled);
  }

  String translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'accepted':
        return 'Aceito';
      case 'in_progress':
        return 'Em Andamento';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}
