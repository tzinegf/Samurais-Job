import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../services/notification_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);
  }
}
