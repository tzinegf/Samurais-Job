import 'package:get/get.dart';
import '../auth/auth_controller.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final authController = Get.find<AuthController>();

  @override
  void onReady() {
    super.onReady();
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(Duration(seconds: 4));

    if (authController.firebaseUser.value == null) {
      Get.offAllNamed(Routes.LOGIN);
    } else {
      // If user is logged in, check if profile is ready
      if (authController.currentUser.value != null) {
        authController.redirectUser();
      } else {
        // If profile is not ready, we can check again or redirect to login.
        // Assuming AuthController handles fetching, if it's taking too long,
        // we might want to go to login or show error.
        // For now, if user exists but profile is null, it's safer to go to Login
        // (or it will eventually redirect if AuthController updates later, but we are navigating away).
        Get.offAllNamed(Routes.LOGIN);
      }
    }
  }
}
