import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'history_controller.dart';
import '../../models/service_request_model.dart';

class HistoryView extends GetView<HistoryController> {
  @override
  Widget build(BuildContext context) {
    // Garante que o controller existe, caso não tenha sido injetado pelo Binding da rota
    if (!Get.isRegistered<HistoryController>()) {
      Get.put(HistoryController());
    }

    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.historyRequests.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum pedido finalizado encontrado.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: controller.historyRequests.length,
        itemBuilder: (context, index) {
          final request = controller.historyRequests[index];
          return Card(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                request.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(request.category),
                  SizedBox(height: 4),
                  Text(
                    'Data: ${request.createdAt != null ? DateFormat('dd/MM/yyyy').format(request.createdAt!) : 'N/A'}',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (request.price != null && request.price! > 0)
                    Text(
                      'Valor: R\$ ${request.price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          (request.hasProblem == true ||
                              request.professionalHasProblem == true)
                          ? Colors.orange.withOpacity(0.1)
                          : (request.status == 'completed'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            (request.hasProblem == true ||
                                request.professionalHasProblem == true)
                            ? Colors.orange
                            : (request.status == 'completed'
                                  ? Colors.green
                                  : Colors.red),
                      ),
                    ),
                    child: Text(
                      (request.hasProblem == true ||
                              request.professionalHasProblem == true)
                          ? 'Não Realizado'
                          : controller.translateStatus(request.status),
                      style: TextStyle(
                        color:
                            (request.hasProblem == true ||
                                request.professionalHasProblem == true)
                            ? Colors.orange
                            : (request.status == 'completed'
                                  ? Colors.green
                                  : Colors.red),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
