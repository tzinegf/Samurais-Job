import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../auth/auth_controller.dart';

class NotificationsController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final notifications = <NotificationModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final user = Get.find<AuthController>().currentUser.value;
    if (user == null) return;

    // Assuming notifications are stored in a subcollection of the user
    // This is a common pattern for private user notifications
    _firestore
        .collection('users')
        .doc(user.id)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      notifications.value = snapshot.docs
          .map((doc) => NotificationModel.fromDocument(doc))
          .toList();
      isLoading.value = false;
    }, onError: (e) {
      print('Erro ao carregar notificações: $e');
      isLoading.value = false;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final user = Get.find<AuthController>().currentUser.value;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Erro ao marcar notificação como lida: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = Get.find<AuthController>().currentUser.value;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Erro ao excluir notificação: $e');
    }
  }
}
