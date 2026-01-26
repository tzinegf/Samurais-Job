import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfessionalSettingsController extends GetxController {
  final notificationsEnabled = true.obs;
  final serviceRadius = 10.0.obs; // Default 10km

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled.value = prefs.getBool('notifications_enabled') ?? true;
    serviceRadius.value = prefs.getDouble('service_radius') ?? 10.0;
  }

  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> updateServiceRadius(double value) async {
    serviceRadius.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('service_radius', value);
  }
}
