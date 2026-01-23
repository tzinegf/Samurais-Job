import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/service_request_model.dart';
import '../../routes/app_routes.dart';
import '../history/history_view.dart';
import 'professional_controller.dart';
import '../auth/auth_controller.dart';
import '../shared/mini_map_viewer.dart';

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
                title: Text('Painel do Profissional'),
              ),
              SliverToBoxAdapter(child: _ProfessionalHeader()),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Colors.blue,
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
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(Icons.check_circle_outline),
                          label: Text('Finalizar Serviço'),
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
          return _buildServiceCard(context, request, isAvailable: true);
        },
      );
    });
  }

  Widget _buildMyRequests() {
    return Obx(() {
      final inProgressRequests = controller.myRequests
          .where((r) => r.status == 'accepted')
          .toList();

      if (inProgressRequests.isEmpty) {
        return Center(child: Text('Nenhum serviço em andamento.'));
      }

      return ListView.builder(
        itemCount: inProgressRequests.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final request = inProgressRequests[index];
          return _buildServiceCard(context, request, isAvailable: false);
        },
      );
    });
  }

  Widget _buildServiceCard(
    BuildContext context,
    ServiceRequestModel request, {
    required bool isAvailable,
  }) {
    return Card(
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

      return Container(
        padding: EdgeInsets.all(16),
        // Use primary color background or similar if not covered by AppBar background
        // But since it's in FlexibleSpaceBar, it might need its own background color if the image isn't there
        // Default AppBar color is blue usually.
        color: Colors.blue,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar and Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(fontSize: 24),
                        )
                      : null,
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
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            ' ${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Get.toNamed(Routes.BUY_COINS),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
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
              ],
            ),
            SizedBox(height: 12),
            // Skills
            if (user.skills != null && user.skills!.isNotEmpty)
              SizedBox(
                height: 40,
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
      child: SafeArea(
        child: Obx(() {
          final user = authController.currentUser.value;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user?.name ?? 'Profissional'),
                accountEmail: Text(user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                decoration: BoxDecoration(color: Colors.blue),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Perfil'),
                onTap: () {
                  Get.back();
                  // Navegar para perfil
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
                  // Navegar para notificações
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
