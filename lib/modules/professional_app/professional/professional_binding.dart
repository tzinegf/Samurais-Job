import 'package:get/get.dart';
import 'professional_controller.dart';
import '../../history/history_controller.dart';

class ProfessionalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfessionalController>(() => ProfessionalController());
    Get.lazyPut<HistoryController>(() => HistoryController());
  }
}
