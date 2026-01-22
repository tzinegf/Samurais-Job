import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/auth_controller.dart';
import 'client_controller.dart';

class ClientDashboardView extends GetView<ClientController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel do Cliente'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Get.find<AuthController>().logout(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.myRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Você ainda não solicitou nenhum serviço.'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showCreateRequestDialog(context),
                  child: Text('Solicitar Novo Serviço'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.myRequests.length,
          itemBuilder: (context, index) {
            final request = controller.myRequests[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(_getIconForCategory(request.category)),
                  backgroundColor: Colors.blue.shade100,
                ),
                title: Text(
                  request.title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.category),
                    Text(
                      'Status: ${_translateStatus(request.status)}',
                      style: TextStyle(
                        color: _getStatusColor(request.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (request.price != null && request.price! > 0)
                      Text('Oferta: R\$ ${request.price!.toStringAsFixed(2)}'),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRequestDialog(context),
        icon: Icon(Icons.add),
        label: Text('Novo Pedido'),
      ),
    );
  }

  void _showCreateRequestDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Solicitar Serviço',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller.titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Título do Pedido',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Vazamento na cozinha',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: controller.descriptionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descrição Detalhada',
                    border: OutlineInputBorder(),
                    hintText: 'Descreva o problema ou o serviço que precisa...',
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Categoria do Profissional:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedCategory.value,
                    items: controller.categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      controller.selectedCategory.value = newValue!;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: controller.priceCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Preço Sugerido (Opcional)',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Cancelar'),
                    ),
                    SizedBox(width: 8),
                    Obx(
                      () => controller.isLoading.value
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () => controller.createRequest(),
                              child: Text('Solicitar'),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'encanador':
        return Icons.plumbing;
      case 'eletricista':
        return Icons.electrical_services;
      case 'pintor':
        return Icons.format_paint;
      case 'limpeza':
        return Icons.cleaning_services;
      case 'jardinagem':
        return Icons.yard;
      case 'informática':
        return Icons.computer;
      case 'mecânico':
        return Icons.car_repair;
      case 'cozinheiro':
        return Icons.restaurant;
      default:
        return Icons.handyman;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'accepted':
        return 'Aceito';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
