import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notificações'),
        backgroundColor: Color(0xFFDE3344),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma notificação encontrada.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            if (notification.id == null) return SizedBox.shrink();

            return Dismissible(
              key: Key(notification.id!),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                if (notification.id != null) {
                  controller.deleteNotification(notification.id!);
                }
              },
              child: Container(
                color: notification.isRead
                    ? Colors.white
                    : Colors.red.withOpacity(0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFDE3344).withOpacity(0.1),
                    child: Icon(
                      Icons.notifications,
                      color: Color(0xFFDE3344),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(notification.body),
                      SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(notification.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!notification.isRead && notification.id != null) {
                      controller.markAsRead(notification.id!);
                    }
                    // Handle navigation
                    try {
                      final notificationService =
                          Get.find<NotificationService>();
                      notificationService.navigateFromNotification(
                        notification.type,
                        notification.relatedId,
                      );
                    } catch (e) {
                      print('Erro ao navegar da notificação: $e');
                    }
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
