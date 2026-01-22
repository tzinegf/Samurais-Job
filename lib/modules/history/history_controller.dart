import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_request_model.dart';
import '../auth/auth_controller.dart';

class HistoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  RxList<ServiceRequestModel> historyRequests = <ServiceRequestModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  void fetchHistory() async {
    isLoading.value = true;
    try {
      final user = _authController.currentUser.value;
      if (user == null) {
        // Tenta recuperar do firebaseUser se currentUser for nulo (edge case)
        if (_authController.firebaseUser.value != null) {
           // Lógica de retry ou espera poderia ser adicionada, mas por enquanto retorna.
           // Idealmente AuthController garante currentUser.
        }
        return;
      }

      Query query = _db.collection('service_requests');

      if (user.role == 'client') {
        query = query.where('clientId', isEqualTo: user.id);
      } else if (user.role == 'professional') {
        query = query.where('professionalId', isEqualTo: user.id);
      } else {
        // Se for admin/moderador, talvez queira ver tudo?
        // Por enquanto, vamos assumir que apenas cliente e profissional usam essa tela.
        // Ou retornar vazio.
      }

      // Filter for completed or cancelled
      query = query.where('status', whereIn: ['completed', 'cancelled']);

      final snapshot = await query.get();

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

    } catch (e) {
      print("Error fetching history: $e");
      Get.snackbar("Erro", "Não foi possível carregar o histórico.");
    } finally {
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
