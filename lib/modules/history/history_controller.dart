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
        query = query.where('professionalId', isEqualTo: user.id);
      }

      // Filter for completed or cancelled
      query = query.where('status', whereIn: ['completed', 'cancelled']);

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
