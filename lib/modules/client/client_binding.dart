import 'package:get/get.dart';
import 'client_controller.dart';
import '../history/history_controller.dart';

class ClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientController>(() => ClientController());
    Get.lazyPut<HistoryController>(() => HistoryController());
  }
}
