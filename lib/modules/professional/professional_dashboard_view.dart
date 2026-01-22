import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/service_request_model.dart';
import 'professional_controller.dart';
import '../auth/auth_controller.dart';

class ProfessionalDashboardView extends GetView<ProfessionalController> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Painel do Profissional'),
          actions: [
            // Coins Display
            Obx(() {
              final coins =
                  Get.find<AuthController>().currentUser.value?.coins ?? 0;
              return Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber),
                  SizedBox(width: 4),
                  Text('$coins', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.green),
                    tooltip: 'Comprar Moedas (Demo)',
                    onPressed: () => controller.addCoins(100),
                  ),
                ],
              );
            }),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => controller.fetchAvailableRequests(),
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => Get.find<AuthController>().logout(),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Disponíveis', icon: Icon(Icons.work_outline)),
              Tab(text: 'Meus Serviços', icon: Icon(Icons.assignment_ind)),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildAvailableRequests(), _buildMyRequests()],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => controller.createDummyRequest(),
          child: Icon(Icons.add),
          tooltip: 'Criar Pedido de Teste',
        ),
      ),
    );
  }

  void _showRequestDetails(ServiceRequestModel request) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              request.title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(request.category)),
                SizedBox(width: 8),
                Text(
                  'R\$ ${request.price?.toStringAsFixed(2) ?? 'A combinar'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Descrição:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              request.description,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 24),
            if (request.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    controller.acceptRequest(request);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(Icons.lock_open),
                  label: Text('Aceitar (20 Moedas)'),
                ),
              )
            else if (request.status == 'accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.snackbar('Chat', 'Abrindo chat com o cliente...');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(Icons.chat),
                  label: Text('Abrir Chat'),
                ),
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAvailableRequests() {
    return Obx(() {
      final user = Get.find<AuthController>().currentUser.value;
      final skills = user?.skills?.join(', ') ?? 'Nenhuma';

      if (controller.availableRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Habilidades: $skills',
                style: TextStyle(color: Colors.grey),
              ), // Debug info
              SizedBox(height: 16),
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhum pedido disponível no momento.'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => controller.createDummyRequest(),
                child: Text('Criar Pedido de Teste'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Text(
          //     'Filtrando por: $skills',
          //     style: TextStyle(fontSize: 12, color: Colors.grey),
          //   ),
          // ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.availableRequests.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final request = controller.availableRequests[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _showRequestDetails(request),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(label: Text(request.category)),
                              Text(
                                'R\$ ${request.price?.toStringAsFixed(2) ?? 'A combinar'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            request.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(request.description),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  controller.acceptRequest(request),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              icon: Icon(Icons.lock_open, size: 18),
                              label: Text('Aceitar (20 Moedas)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMyRequests() {
    return Obx(() {
      if (controller.myRequests.isEmpty) {
        return Center(child: Text('Você ainda não aceitou nenhum serviço.'));
      }

      return ListView.builder(
        itemCount: controller.myRequests.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final request = controller.myRequests[index];
          return Card(
            color: Colors.green.shade50,
            elevation: 2,
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              onTap: () => _showRequestDetails(request),
              title: Text(request.title),
              subtitle: Text(request.status.toUpperCase()),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      );
    });
  }
}
