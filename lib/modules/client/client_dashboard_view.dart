import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/service_request_model.dart';
import '../../routes/app_routes.dart';
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
            icon: Icon(Icons.history),
            onPressed: () => Get.toNamed(Routes.HISTORY),
            tooltip: 'Histórico',
          ),
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
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _showRequestDetails(context, request),
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
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                request.status,
                              ).withOpacity(0.1),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                          if (request.price != null && request.price! > 0)
                            Text(
                              'R\$ ${request.price!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            )
                          else
                            Text(
                              'A combinar',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (request.status == 'pending')
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () =>
                                      _showEditRequestDialog(context, request),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _confirmDeleteRequest(context, request),
                                  tooltip: 'Excluir',
                                ),
                              ],
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
                                backgroundColor: Colors.blue,
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

  void _showRequestDetails(BuildContext context, ServiceRequestModel request) {
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
                    _translateStatus(request.status),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(request.status),
                    ),
                  ),
                ],
              ),
              if (request.price != null && request.price! > 0) ...[
                SizedBox(height: 8),
                Text(
                  'Oferta: R\$ ${request.price!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ] else ...[
                SizedBox(height: 8),
                Text(
                  'Oferta: A combinar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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

              if (request.status == 'accepted' &&
                  request.professionalId != null) ...[
                SizedBox(height: 24),
                Divider(),
                SizedBox(height: 16),
                Text(
                  'Profissional Responsável:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>?>(
                  future: controller.getProfessionalDetails(
                    request.professionalId!,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Text(
                        'Não foi possível carregar os dados do profissional.',
                      );
                    }

                    final proData = snapshot.data!;
                    final skills = proData['skills'] != null
                        ? (proData['skills'] as List).join(', ')
                        : 'Nenhuma habilidade listada';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              (proData['name'] as String?)
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'P',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            proData['name'] ?? 'Profissional',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(proData['email'] ?? ''),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Habilidades:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(skills),
                        if (proData['bio'] != null &&
                            (proData['bio'] as String).isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            'Sobre:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(proData['bio']),
                        ],
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.back(); // Fecha o bottom sheet
                              Get.toNamed(
                                Routes.CHAT,
                                arguments: {
                                  'requestId': request.id,
                                  'requestTitle': request.title,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.chat),
                            label: Text('Conversar com Profissional'),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.back(); // Fecha o bottom sheet
                              _showFinishRequestDialog(context, request);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.check_circle_outline),
                            label: Text('Finalizar Serviço'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCreateRequestDialog(BuildContext context) {
    controller.titleCtrl.clear();
    controller.descriptionCtrl.clear();
    controller.priceCtrl.clear();
    controller.selectedCategory.value = controller.categories.first;

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
                    labelText: 'Título (ex: Consertar Torneira)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedCategory.value,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      controller.selectedCategory.value = newValue!;
                    },
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller.descriptionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Descrição detalhada',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller.priceCtrl,
                  decoration: InputDecoration(
                    labelText: 'Oferta de Preço (R\$) - Opcional',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 24),
                Obx(
                  () => controller.isLoading.value
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: controller.createRequest,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('ENVIAR SOLICITAÇÃO'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditRequestDialog(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    controller.titleCtrl.text = request.title;
    controller.descriptionCtrl.text = request.description;
    controller.priceCtrl.text = request.price?.toStringAsFixed(2) ?? '';
    if (controller.categories.contains(request.category)) {
      controller.selectedCategory.value = request.category;
    } else {
      controller.selectedCategory.value = controller.categories.first;
    }

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
                  'Editar Serviço',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller.titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedCategory.value,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      controller.selectedCategory.value = newValue!;
                    },
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller.descriptionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Descrição detalhada',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller.priceCtrl,
                  decoration: InputDecoration(
                    labelText: 'Oferta de Preço (R\$) - Opcional',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 24),
                Obx(
                  () => controller.isLoading.value
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () {
                            if (request.id != null) {
                              controller.updateRequest(request.id!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('SALVAR ALTERAÇÕES'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRequest(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Excluir Pedido'),
        content: Text('Tem certeza que deseja excluir este pedido?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back(); // Fecha o diálogo de confirmação
              if (request.id != null) {
                controller.deleteRequest(request.id!);
              }
            },
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
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
        return Icons.cut; // Usando ícone genérico, ajuste se necessário
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

  void _showFinishRequestDialog(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    if (request.id == null) return;

    Get.dialog(
      AlertDialog(
        title: Text('Finalizar Serviço'),
        content: Text('O serviço foi finalizado com sucesso?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _showFeedbackDialog(context, request, hasProblem: true);
            },
            child: Text(
              'Não, houve problema',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showFeedbackDialog(context, request, hasProblem: false);
            },
            child: Text('Sim, tudo certo'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(
    BuildContext context,
    ServiceRequestModel request, {
    required bool hasProblem,
  }) {
    final rating = 5.0.obs;
    final reviewCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  hasProblem ? 'Relatar Problema' : 'Avaliar Profissional',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                if (hasProblem)
                  Text(
                    'Por favor, descreva o problema ocorrido e avalie o profissional (opcional).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  )
                else
                  Text(
                    'Como foi sua experiência com o profissional?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                SizedBox(height: 24),
                Center(
                  child: Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating.value
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            rating.value = index + 1.0;
                          },
                        );
                      }),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: reviewCtrl,
                  decoration: InputDecoration(
                    labelText: hasProblem
                        ? 'Descrição do Problema'
                        : 'Sua Opinião',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 24),
                Obx(
                  () => controller.isLoading.value
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () {
                            if (hasProblem && reviewCtrl.text.isEmpty) {
                              Get.snackbar(
                                'Erro',
                                'Por favor, descreva o problema.',
                              );
                              return;
                            }
                            controller.finishRequest(
                              requestId: request.id!,
                              rating: rating.value,
                              review: reviewCtrl.text,
                              hasProblem: hasProblem,
                              problemDescription: hasProblem
                                  ? reviewCtrl.text
                                  : null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: hasProblem
                                ? Colors.red
                                : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            hasProblem
                                ? 'Reportar e Finalizar'
                                : 'Finalizar e Avaliar',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
