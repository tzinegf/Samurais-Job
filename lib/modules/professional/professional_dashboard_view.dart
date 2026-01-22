import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/service_request_model.dart';
import '../../routes/app_routes.dart';
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
              icon: Icon(Icons.history),
              onPressed: () => Get.toNamed(Routes.HISTORY),
              tooltip: 'Histórico',
            ),
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
        child: SingleChildScrollView(
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
                      Get.toNamed(
                        Routes.CHAT,
                        arguments: {
                          'requestId': request.id,
                          'requestTitle': request.title,
                        },
                      );
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

      return ListView.builder(
        itemCount: controller.availableRequests.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final request = controller.availableRequests[index];
          return _buildServiceCard(request, isAvailable: true);
        },
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
          return _buildServiceCard(request, isAvailable: false);
        },
      );
    });
  }

  Widget _buildServiceCard(
    ServiceRequestModel request, {
    required bool isAvailable,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForCategory(request.category),
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        request.category,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (!isAvailable)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(
                            request.status,
                          ).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _translateStatus(request.status),
                        style: TextStyle(
                          color: _getStatusColor(request.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                request.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                request.createdAt != null
                    ? 'Criado em ${DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt!)}'
                    : 'Data desconhecida',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              SizedBox(height: 8),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[800], height: 1.3),
              ),
              SizedBox(height: 12),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (request.price != null && request.price! > 0)
                        ? 'R\$ ${request.price!.toStringAsFixed(2)}'
                        : 'A combinar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (request.price != null && request.price! > 0)
                          ? Colors.green[700]
                          : Colors.grey,
                    ),
                  ),
                  if (isAvailable)
                    ElevatedButton.icon(
                      onPressed: () => controller.acceptRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                      icon: Icon(Icons.lock_open, size: 16),
                      label: Text('Aceitar'),
                    )
                  else if (request.status == 'accepted')
                    ElevatedButton.icon(
                      onPressed: () => Get.toNamed(
                        Routes.CHAT,
                        arguments: {
                          'requestId': request.id,
                          'requestTitle': request.title,
                        },
                      ),
                      icon: Icon(Icons.chat, size: 16),
                      label: Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Marceneiro':
        return Icons.carpenter;
      case 'Encanador':
        return Icons.plumbing;
      case 'Pedreiro':
        return Icons.construction;
      case 'Eletricista':
        return Icons.electric_bolt;
      case 'Pintor':
        return Icons.format_paint;
      case 'Jardinagem':
        return Icons.grass;
      case 'Limpeza':
        return Icons.cleaning_services;
      case 'Mecânico':
        return Icons.car_repair;
      case 'Informática':
        return Icons.computer;
      case 'Costureira':
        return Icons.cut;
      case 'Cozinheiro':
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
