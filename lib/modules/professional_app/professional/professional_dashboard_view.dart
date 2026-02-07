import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/service_request_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/ranking_system.dart';
import '../../history/history_view.dart';
import 'professional_controller.dart';
import '../../auth/auth_controller.dart';
import '../../shared/mini_map_viewer.dart';
import '../../../utils/content_validator.dart';
import '../../../services/notification_service.dart';

ImageProvider? _getAvatarImage(String? avatarUrl) {
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    if (avatarUrl.startsWith('data:image')) {
      try {
        final base64String = avatarUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print('Erro ao decodificar imagem Base64: $e');
        return null;
      }
    }
    return NetworkImage(avatarUrl);
  }
  return null;
}

class ProfessionalDashboardView extends GetView<ProfessionalController> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: _ProfessionalDrawer(),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                floating: false,
                pinned: true,
                centerTitle: true,
                title: Text('Painel do Samurai'),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications),
                        onPressed: () => Get.toNamed(Routes.NOTIFICATIONS),
                      ),
                      Obx(() {
                        final notificationService =
                            Get.find<NotificationService>();
                        if (notificationService.unreadCount.value > 0) {
                          return Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  '${notificationService.unreadCount.value}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      }),
                    ],
                  ),
                ],
              ),
              SliverToBoxAdapter(child: _ProfessionalHeader()),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Color(0xFFDE3344),
                    indicatorColor: Color(0xFFDE3344),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Disponíveis', icon: Icon(Icons.work_outline)),
                      Tab(
                        text: 'Meus Serviços',
                        icon: Icon(Icons.assignment_ind),
                      ),
                      Tab(text: 'Histórico', icon: Icon(Icons.history)),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildAvailableRequests(),
              _buildMyRequests(),
              HistoryView(),
            ],
          ),
        ),
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
                  Chip(
                    label: Text(request.category),
                    backgroundColor: Color(0xFFDE3344),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  if (request.subcategory != null) ...[
                    Chip(
                      label: Text(request.subcategory!),
                      backgroundColor: Colors.grey[200],
                    ),
                    SizedBox(width: 8),
                  ],
                ],
              ),
              if (request.service != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      request.service!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 16),
              Text(
                'R\$ ${request.price?.toStringAsFixed(2) ?? 'A combinar'}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
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
              if (request.latitude != null && request.longitude != null) ...[
                SizedBox(height: 16),
                Text(
                  'Localização:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                MiniMapViewer(
                  latitude: request.latitude!,
                  longitude: request.longitude!,
                ),
              ],
              SizedBox(height: 24),
              if (request.status == 'pending')
                if (request.quotedBy.contains(
                  Get.find<AuthController>().currentUser.value?.id,
                ))
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('service_requests')
                        .doc(request.id)
                        .collection('quotes')
                        .where(
                          'professionalId',
                          isEqualTo:
                              Get.find<AuthController>().currentUser.value?.id,
                        )
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: Colors.orange.shade100,
                              disabledForegroundColor: Colors.orange.shade800,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.hourglass_empty),
                            label: Text('Aguardando retorno do cliente'),
                          ),
                        );
                      }

                      final quoteData =
                          snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                      final status = quoteData['status'];

                      if (status == 'rejected') {
                        final reason = quoteData['rejectionReason'] ?? '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Proposta Recusada',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (reason.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      'Motivo: "$reason"',
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      if (status == 'adjustment_requested') {
                        final comment = quoteData['clientComment'] ?? '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFDE3344).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFFDE3344).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Color(0xFFDE3344),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Cliente solicitou ajuste:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDE3344),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (comment.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      '"$comment"',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Get.back();
                                _showQuoteDialog(context, request);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFDE3344),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: Icon(Icons.edit),
                              label: Text('Enviar Novo Orçamento'),
                            ),
                          ],
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: Colors.orange.shade100,
                            disabledForegroundColor: Colors.orange.shade800,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(Icons.hourglass_empty),
                          label: Text('Aguardando retorno do cliente'),
                        ),
                      );
                    },
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        _showQuoteDialog(context, request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFDE3344),
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
                  child: Column(
                    children: [
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
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
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
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showCancelConfirmationDialog(context, request);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(Icons.cancel_outlined),
                          label: Text('Cancelar Serviço'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCancelConfirmationDialog(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Cancelar Serviço?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja cancelar este serviço?'),
            SizedBox(height: 16),
            Text(
              'Atenção: Cancelamentos impactam negativamente seu Ranking Samurai e podem levar ao rebaixamento de nível.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Não, manter')),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Close details
              controller.cancelService(request.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sim, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuoteDialog(BuildContext context, ServiceRequestModel request) {
    final priceController = TextEditingController(
      text: request.price?.toStringAsFixed(2) ?? '',
    );
    final descriptionController = TextEditingController();
    final selectedDeadline = RxnString();
    final isExclusive = false.obs;

    final List<String> deadlineOptions = [
      'Imediato',
      '1 dia',
      '2 dias',
      '3 dias',
      '5 dias',
      '1 semana',
      '15 dias',
      '1 mês',
      'A combinar',
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enviar Orçamento',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor (R\$)',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descrição / Proposta',
                    border: OutlineInputBorder(),
                    hintText: 'Descreva o que está incluso no serviço...',
                  ),
                ),
                SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Prazo de Execução',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    value: selectedDeadline.value,
                    items: deadlineOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      selectedDeadline.value = newValue;
                    },
                  ),
                ),
                SizedBox(height: 12),
                Obx(
                  () => SwitchListTile(
                    title: Text(
                      'Orçamento Exclusivo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Pague o dobro (${ProfessionalController.EXCLUSIVE_QUOTE_COST} moedas) para ser o ÚNICO a enviar orçamentos a partir de agora.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: isExclusive.value,
                    onChanged: (val) => isExclusive.value = val,
                    activeColor: Colors.amber,
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
                    SizedBox(width: 12),
                    Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                final price = double.tryParse(
                                  priceController.text.replaceAll(',', '.'),
                                );
                                final desc = descriptionController.text.trim();
                                final deadline = selectedDeadline.value;

                                if (price == null || price <= 0) {
                                  Get.snackbar(
                                    'Erro',
                                    'Informe um valor válido.',
                                  );
                                  return;
                                }

                                if (desc.isEmpty) {
                                  Get.snackbar(
                                    'Erro',
                                    'Informe uma descrição.',
                                  );
                                  return;
                                }

                                if (deadline == null || deadline.isEmpty) {
                                  Get.snackbar(
                                    'Erro',
                                    'Selecione o prazo de execução.',
                                  );
                                  return;
                                }

                                // Validate Content
                                final validation = ContentValidator.validate(
                                  desc,
                                );
                                if (!validation.isValid) {
                                  Get.snackbar(
                                    'Conteúdo Proibido',
                                    validation.errorMessage ??
                                        'Conteúdo não permitido no orçamento.',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                    duration: Duration(seconds: 5),
                                  );
                                  return;
                                }

                                controller.sendQuote(
                                  request,
                                  price,
                                  desc,
                                  isExclusive.value,
                                  deadline,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDE3344),
                          foregroundColor: Colors.white,
                        ),
                        child: controller.isLoading.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Enviar'),
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

  Widget _buildAvailableRequests() {
    return Column(
      children: [
        // Filter Chips
        Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Obx(
                () => FilterChip(
                  label: Text('Urgente'),
                  selected: controller.currentFilter.value == 'urgency_high',
                  onSelected: (bool selected) {
                    if (selected)
                      controller.currentFilter.value = 'urgency_high';
                  },
                  selectedColor: Color(0xFFDE3344).withOpacity(0.1),
                  checkmarkColor: Color(0xFFDE3344),
                ),
              ),
              SizedBox(width: 8),
              Obx(
                () => FilterChip(
                  label: Text('Mais Recentes'),
                  selected: controller.currentFilter.value == 'recent',
                  onSelected: (bool selected) {
                    if (selected) controller.currentFilter.value = 'recent';
                  },
                  selectedColor: Color(0xFFDE3344).withOpacity(0.1),
                  checkmarkColor: Color(0xFFDE3344),
                ),
              ),
              SizedBox(width: 8),
              Obx(
                () => FilterChip(
                  label: Text('Mais Próximos'),
                  selected: controller.currentFilter.value == 'nearest',
                  onSelected: (bool selected) {
                    if (selected) {
                      controller.currentFilter.value = 'nearest';
                      if (controller.currentPosition.value == null) {
                        controller.getCurrentLocation();
                      }
                    }
                  },
                  selectedColor: Color(0xFFDE3344).withOpacity(0.1),
                  checkmarkColor: Color(0xFFDE3344),
                ),
              ),
              SizedBox(width: 8),
              Obx(
                () => FilterChip(
                  label: Text('Maior Valor'),
                  selected: controller.currentFilter.value == 'price_desc',
                  onSelected: (bool selected) {
                    if (selected) controller.currentFilter.value = 'price_desc';
                  },
                  selectedColor: Color(0xFFDE3344).withOpacity(0.1),
                  checkmarkColor: Color(0xFFDE3344),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final user = Get.find<AuthController>().currentUser.value;
            final skills = user?.skills?.join(', ') ?? 'Nenhuma';

            if (controller.availableRequests.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_off_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum pedido disponível para suas habilidades no momento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Suas habilidades: $skills',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: controller.availableRequests.length,
              itemBuilder: (context, index) {
                final request = controller.availableRequests[index];
                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
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
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Chip(
                                      label: Text(
                                        request.category,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Color(0xFFDE3344),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    if (request.subcategory != null) ...[
                                      Chip(
                                        label: Text(
                                          request.subcategory!,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: Colors.grey[200],
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                    if (request.urgency != null)
                                      _buildUrgencyBadge(request.urgency!),
                                    if (request.quotedBy.contains(
                                      Get.find<AuthController>()
                                          .currentUser
                                          .value
                                          ?.id,
                                    ))
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('service_requests')
                                            .doc(request.id)
                                            .collection('quotes')
                                            .where(
                                              'professionalId',
                                              isEqualTo:
                                                  Get.find<AuthController>()
                                                      .currentUser
                                                      .value
                                                      ?.id,
                                            )
                                            .limit(1)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          String text = 'Proposta Enviada';
                                          Color color = Colors.blue.shade100;
                                          Color textColor =
                                              Colors.blue.shade900;

                                          if (snapshot.hasData &&
                                              snapshot.data!.docs.isNotEmpty) {
                                            final data =
                                                snapshot.data!.docs.first.data()
                                                    as Map<String, dynamic>;
                                            final status =
                                                (data['status'] ?? '')
                                                    .toString();

                                            if (status == 'rejected') {
                                              text = 'Proposta Recusada';
                                              color = Colors.red.shade100;
                                              textColor = Colors.red.shade900;
                                            } else if (status == 'accepted') {
                                              text = 'Proposta Aceita';
                                              color = Colors.green.shade100;
                                              textColor = Colors.green.shade900;
                                            } else if (status ==
                                                'adjustment_requested') {
                                              text = 'Ajuste Solicitado';
                                              color = Colors.amber.shade100;
                                              textColor = Colors.amber.shade900;
                                            }
                                          }

                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
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
                          if (request.service != null) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.build_circle_outlined,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  request.service!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: 8),
                          Text(
                            request.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          if (controller.currentFilter.value == 'nearest' &&
                              controller.currentPosition.value != null &&
                              request.latitude != null &&
                              request.longitude != null) ...[
                            SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final Distance distance = Distance();
                                final km =
                                    distance.as(
                                      LengthUnit.Meter,
                                      controller.currentPosition.value!,
                                      LatLng(
                                        request.latitude!,
                                        request.longitude!,
                                      ),
                                    ) /
                                    1000;
                                return Text(
                                  '${km.toStringAsFixed(1)} km de distância',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                          SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              request.createdAt != null
                                  ? DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(request.createdAt!)
                                  : '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMyRequests() {
    return Obx(() {
      // Filter to show only 'accepted' requests (Active Jobs)
      // Completed and Cancelled should be in History
      final myRequests = controller.myRequests
          .where((req) => req.status == 'accepted')
          .toList();

      if (myRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhum serviço em andamento.'),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: myRequests.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final request = myRequests[index];

          final currentUserId =
              Get.find<AuthController>().currentUser.value?.id;

          // Since we filter only 'accepted', status is always 'Aceito'
          // and professionalId check is redundant if controller filters by ID,
          // but we keep the logic for safety or future changes.
          String statusDisplay = 'Aceito (Em Andamento)';
          Color statusColor = Colors.green;

          return _buildServiceCard(
            context,
            request,
            isAvailable: false,
            customStatusText: statusDisplay,
            customStatusColor: statusColor,
          );
        },
      );
    });
  }

  Widget _buildServiceCard(
    BuildContext context,
    ServiceRequestModel request, {
    required bool isAvailable,
    String? customStatusText,
    Color? customStatusColor,
  }) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFDE3344).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForCategory(request.category),
                            color: Color(0xFFDE3344),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            request.category,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (request.subcategory != null) ...[
                          SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              request.subcategory!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isAvailable)
                    Builder(
                      builder: (context) {
                        String statusText =
                            customStatusText ??
                            _translateStatus(request.status);
                        Color statusColor =
                            customStatusColor ??
                            _getStatusColor(request.status);

                        if (customStatusText == null &&
                            request.status == 'completed' &&
                            request.rating == null) {
                          statusText = 'Aguardando Avaliação';
                          statusColor = Colors.orange;
                        }

                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                request.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (request.service != null) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      request.service!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
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
              SizedBox(height: 8),
              if (isAvailable) ...[
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Orçamentos: ${request.quoteCount}/3',
                      style: TextStyle(
                        color: request.quoteCount >= 3
                            ? Colors.red
                            : Colors.grey[700],
                        fontWeight: request.quoteCount >= 3
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (request.quoteCount >= 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '(Limite atingido)',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
              ],
              if (controller.currentFilter.value == 'nearest' &&
                  controller.currentPosition.value != null &&
                  request.latitude != null &&
                  request.longitude != null) ...[
                SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final Distance distance = Distance();
                    final dist = distance.as(
                      LengthUnit.Kilometer,
                      controller.currentPosition.value!,
                      LatLng(request.latitude!, request.longitude!),
                    );
                    return Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Aprox. ${dist.toStringAsFixed(1)} km',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    );
                  },
                ),
              ],
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
                      onPressed: request.quoteCount >= 3
                          ? null // Disable if limit reached
                          : () => _showQuoteDialog(context, request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFDE3344),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: TextStyle(fontSize: 12),
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                      ),
                      icon: Icon(Icons.send, size: 16),
                      label: Text('Orçar'),
                    )
                  else if (request.status == 'accepted' &&
                      request.professionalId ==
                          Get.find<AuthController>().currentUser.value?.id)
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

  Widget _buildUrgencyBadge(String urgency) {
    Color color;
    String text;
    IconData icon;
    String tooltip;

    final cleanUrgency = urgency.toLowerCase().trim();

    if (cleanUrgency.contains('quanto antes') ||
        cleanUrgency == 'immediate' ||
        cleanUrgency == 'urgente' ||
        cleanUrgency == 'imediato') {
      color = Colors.red;
      text = 'Urgente';
      icon = Icons.warning_amber_rounded;
      tooltip = 'Quanto antes melhor';
    } else if (cleanUrgency.contains('5 dias')) {
      color = Colors.deepOrange;
      text = 'Imediato';
      icon = Icons.priority_high_rounded;
      tooltip = 'Nos próximos 5 dias';
    } else if (cleanUrgency.contains('15 dias') ||
        cleanUrgency == 'high' ||
        cleanUrgency == 'alta' ||
        cleanUrgency == 'alto') {
      color = Colors.orange;
      text = 'Alta';
      icon = Icons.schedule;
      tooltip = 'Nos próximos 15 dias';
    } else if (cleanUrgency.contains('30 dias') ||
        cleanUrgency.contains('medium') ||
        cleanUrgency.contains('media') ||
        cleanUrgency.contains('média') ||
        cleanUrgency.contains('medio') ||
        cleanUrgency.contains('médio')) {
      color = Colors.blue;
      text = 'Média';
      icon = Icons.calendar_today;
      tooltip = 'Nos próximos 30 dias';
    } else {
      // Default / Low / Sem data
      color = Colors.green;
      text = 'Baixa';
      icon = Icons.low_priority;
      tooltip = 'Sem data definida';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            SizedBox(width: 4),
            Text(
              text.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
        return Colors.green;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finalizar Serviço'),
        content: Text('O serviço foi realizado com sucesso?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFeedbackDialog(context, request, hasProblem: true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Teve Problema'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFeedbackDialog(context, request, hasProblem: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Sim, Sucesso'),
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
    final _reviewController = TextEditingController();
    final _problemController = TextEditingController();
    double _rating = 5.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(hasProblem ? 'Relatar Problema' : 'Avaliar Cliente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasProblem) ...[
                      Text(
                        'Descreva o problema encontrado (Obrigatório):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _problemController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'Ex: Cliente não compareceu, local inseguro...',
                        ),
                      ),
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 16),
                    ],
                    Text(
                      'Avalie o Cliente:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Opinião sobre o Cliente (Opcional):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _reviewController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Ex: Cliente atencioso, pagou corretamente...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (hasProblem && _problemController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Erro',
                        'Por favor, descreva o problema.',
                        backgroundColor: Colors.red.withOpacity(0.1),
                        colorText: Colors.red,
                      );
                      return;
                    }

                    controller.finishRequest(
                      requestId: request.id!,
                      clientId: request.clientId,
                      clientRating: _rating,
                      clientReview: _reviewController.text,
                      professionalHasProblem: hasProblem,
                      professionalProblemDescription: hasProblem
                          ? _problemController.text
                          : null,
                    );
                  },
                  child: Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _ProfessionalHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final professionalController = Get.find<ProfessionalController>();

    return Obx(() {
      final user = authController.currentUser.value;
      if (user == null) return SizedBox();

      // Calculate Rank
      final rankLevel = RankingSystem.calculateRank(
        user.completedServicesCount,
        user.rating,
        user.cancellationCount,
      );
      final rankName = RankingSystem.getRankName(rankLevel);
      final rankTitle = RankingSystem.getRankTitle(rankLevel);
      final rankColor = RankingSystem.getRankColor(rankLevel);
      final rankIcon = RankingSystem.getRankIcon(rankLevel);
      final rankImage = RankingSystem.getRankImage(rankLevel);
      final rankQuote = RankingSystem.getRankQuote(rankLevel);

      // Calculate Progress
      final double progress = RankingSystem.getNextLevelProgress(
        user.completedServicesCount,
        user.rating,
      );

      final nextLevelReq = RankingSystem.getNextLevelRequirement(
        user.completedServicesCount,
        user.rating,
        user.cancellationCount,
      );
      final String nextLevelText = progress < 1.0
          ? 'Próximo Nível: ${nextLevelReq['next']}'
          : 'Nível Máximo Alcançado';

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDE3344), const Color.fromARGB(255, 0, 0, 0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar and Info Row
            Row(
              children: [
                InkWell(
                  onTap: () => Get.toNamed(Routes.PROFILE),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: rankColor, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: _getAvatarImage(user.avatarUrl),
                      child: user.avatarUrl == null
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Image.asset(rankImage, width: 24, height: 24),
                          SizedBox(width: 8),
                          Expanded(
                            // Added Expanded to prevent overflow
                            child: Text(
                              '$rankName — $rankTitle',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            ' ${user.rating.toStringAsFixed(1)} (${user.ratingCount.toStringAsFixed(0)})',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.work, color: Colors.white70, size: 14),
                          Text(
                            ' ${user.completedServicesCount} serviços',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'O rating é calculado com base na sua trajetória e avaliações reais.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => Get.toNamed(Routes.BUY_COINS),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${user.coins}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    InkWell(
                      onTap: () => Get.toNamed(Routes.RANKING_DETAILS),
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        rankImage,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            // Ranking Quote & Progress
            InkWell(
              onTap: () => Get.toNamed(Routes.RANKING_DETAILS),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rankQuote,
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          nextLevelText,
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12),
            // Skills
            if (user.skills != null && user.skills!.isNotEmpty)
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: user.skills!
                      .map(
                        (s) => Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(s, style: TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ProfessionalDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final professionalController = Get.find<ProfessionalController>();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Obx(() {
          final user = authController.currentUser.value;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user?.name ?? 'Profissional'),
                accountEmail: Text(user?.email ?? ''),
                currentAccountPicture: GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.toNamed(Routes.PROFILE);
                  },
                  child: CircleAvatar(
                    backgroundImage: _getAvatarImage(user?.avatarUrl),
                    child: user?.avatarUrl == null
                        ? Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                ),
                decoration: BoxDecoration(color: Color(0xFFDE3344)),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Meu Perfil'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.PROFILE);
                },
              ),
              ListTile(
                leading: Icon(Icons.monetization_on),
                title: Text('Moedas (Comprar)'),
                trailing: Text('${user?.coins ?? 0}'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.BUY_COINS);
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notificações'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.NOTIFICATIONS);
                },
              ),
              ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Atualizar Pedidos'),
                onTap: () {
                  Get.back();
                  professionalController.fetchAvailableRequests();
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Configurações'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.PROFESSIONAL_SETTINGS);
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.history_edu, color: Color(0xFFDE3344)),
                title: Text('Manifesto Samurai'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.MANIFESTO);
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Sair'),
                onTap: () => authController.logout(),
              ),
            ],
          );
        }),
      ),
    );
  }
}
