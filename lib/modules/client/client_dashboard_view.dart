import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../models/service_request_model.dart';
import '../../models/quote_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/ranking_system.dart';
import '../history/history_view.dart';
import '../auth/auth_controller.dart';
import 'client_controller.dart';
import '../shared/location_picker_view.dart';
import '../shared/mini_map_viewer.dart';

import '../../services/database_seeder.dart';

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

class ClientDashboardView extends GetView<ClientController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRequestDialog(context),
        icon: Icon(Icons.add),
        label: Text('Novo Pedido'),
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      floating: false,
                      pinned: true,
                      title: Text('Painel do Cliente'),
                    ),
                    SliverToBoxAdapter(child: _ClientHeader()),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          labelColor: Color(0xFFDE3344),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Color(0xFFDE3344),
                          tabs: [
                            Tab(
                              text: 'Meus Pedidos',
                              icon: Icon(Icons.list_alt),
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
              children: [_buildActiveRequests(context), HistoryView()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Drawer(
      child: Obx(() {
        final user = authController.currentUser.value;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'Usuário'),
              accountEmail: Text(user?.email ?? 'email@exemplo.com'),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.PROFILE);
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: _getAvatarImage(user?.avatarUrl),
                  child: user?.avatarUrl == null
                      ? Text(
                          (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 40.0,
                            color: Color(0xFFDE3344),
                          ),
                        )
                      : null,
                ),
              ),
              decoration: BoxDecoration(color: Color(0xFFDE3344)),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Início'),
              onTap: () {
                Get.back(); // Close drawer
              },
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
              leading: Icon(Icons.settings),
              title: Text('Configurações'),
              onTap: () {
                Get.back();
                // TODO: Navigate to settings
                Get.snackbar(
                  'Em breve',
                  'Funcionalidade de configurações em desenvolvimento',
                );
              },
            ),
            // Admin Seed Menu in Drawer
            if (user?.role == 'admin' ||
                user?.email == 'eg_f1@hotmail.com') ...[
              Divider(),
              ListTile(
                leading: Icon(Icons.cloud_upload),
                title: Text('Atualizar BD (Seed)'),
                onTap: () {
                  Get.back();
                  _runSeeder();
                },
              ),
            ],
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Sair', style: TextStyle(color: Colors.red)),
              onTap: () {
                authController.logout();
              },
            ),
          ],
        );
      }),
    );
  }

  void _runSeeder() {
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    DatabaseSeeder()
        .seed()
        .then((_) {
          Get.back(); // Close loading
          Get.snackbar(
            'Sucesso',
            'Categorias e serviços atualizados com sucesso!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        })
        .catchError((e) {
          Get.back(); // Close loading
          Get.snackbar(
            'Erro',
            'Erro ao atualizar: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
  }

  Widget _buildActiveRequests(BuildContext context) {
    return Obx(() {
      final activeRequests = controller.myRequests
          .where((r) => r.status != 'completed' && r.status != 'cancelled')
          .toList();

      if (activeRequests.isEmpty) {
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
        itemCount: activeRequests.length,
        itemBuilder: (context, index) {
          final request = activeRequests[index];
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
                            Text(
                              request.category,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (request.quoteCount > 0 &&
                                request.status == 'pending') ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.purple.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      size: 14,
                                      color: Colors.purple.shade800,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${request.quoteCount} Orçamento${request.quoteCount > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Colors.purple.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
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
                                icon: Icon(
                                  Icons.edit,
                                  color: Color(0xFFDE3344),
                                ),
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
                          )
                        else if (request.status == 'completed' &&
                            request.rating == null)
                          ElevatedButton.icon(
                            onPressed: () {
                              _showFinishRequestDialog(context, request);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: TextStyle(fontSize: 12),
                            ),
                            icon: Icon(Icons.star, size: 16),
                            label: Text('Avaliar'),
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
    });
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

              if (request.status == 'pending') ...[
                SizedBox(height: 24),
                Divider(),
                SizedBox(height: 16),
                Text(
                  'Orçamentos Recebidos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 16),
                StreamBuilder<List<QuoteModel>>(
                  stream: controller.getQuotes(request.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Erro ao carregar orçamentos.');
                    }
                    final quotes = snapshot.data ?? [];
                    if (quotes.isEmpty) {
                      return Text(
                        'Nenhum orçamento recebido ainda.',
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: quotes.length,
                      itemBuilder: (context, index) {
                        final quote = quotes[index];
                        final rankLevel = RankingSystem.getLevelFromString(
                          quote.professionalRank ?? 'ronin',
                        );
                        final rankName = RankingSystem.getRankName(rankLevel);
                        final rankColor = RankingSystem.getRankColor(rankLevel);
                        final rankIcon = RankingSystem.getRankIcon(rankLevel);
                        final rankImage = RankingSystem.getRankImage(rankLevel);

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quote.professionalName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Image.asset(
                                              rankImage,
                                              width: 20,
                                              height: 20,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              rankName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: rankColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (rankLevel.index >=
                                                RankingLevel
                                                    .ashigaru
                                                    .index) ...[
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.verified,
                                                size: 14,
                                                color: rankColor,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'R\$ ${quote.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                if (quote.professionalRating != null ||
                                    quote.professionalCompletedServices != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        if (quote.professionalRating !=
                                            null) ...[
                                          Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            quote.professionalRating!
                                                .toStringAsFixed(1),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                        ],
                                        if (quote
                                                .professionalCompletedServices !=
                                            null) ...[
                                          Icon(
                                            Icons.work_outline,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${quote.professionalCompletedServices} serviços',
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                Text(quote.description),
                                SizedBox(height: 12),
                                if (quote.isExclusive)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Orçamento Exclusivo',
                                          style: TextStyle(
                                            color: Colors.amber[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (quote.status == 'rejected')
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Orçamento Recusado',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (quote.status == 'accepted')
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Orçamento Aceito',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (quote.status == 'adjustment_requested')
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Ajuste Solicitado',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _showRequestAdjustmentDialog(
                                                context,
                                                request,
                                                quote,
                                              ),
                                          icon: Icon(
                                            Icons.edit_note,
                                            color: Colors.orange,
                                          ),
                                          label: Text(
                                            'Solicitar Ajuste',
                                            style: TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            side: BorderSide(
                                              color: Colors.orange,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _showRejectQuoteDialog(
                                                    context,
                                                    request,
                                                    quote,
                                                  ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: BorderSide(
                                                  color: Colors.red,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                              ),
                                              child: Text('Recusar'),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _showAcceptQuoteDialog(
                                                  context,
                                                  request,
                                                  quote,
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(
                                                  0xFFDE3344,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                              ),
                                              child: Text('Aceitar'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],

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

                    final double rating = (proData['rating'] is int)
                        ? (proData['rating'] as int).toDouble()
                        : (proData['rating'] as double?) ?? 0.0;
                    final int ratingCount = proData['ratingCount'] ?? 0;

                    final rankLevel = RankingSystem.getLevelFromString(
                      proData['ranking'] ?? 'ronin',
                    );
                    final rankName = RankingSystem.getRankName(rankLevel);
                    final rankColor = RankingSystem.getRankColor(rankLevel);
                    final rankImage = RankingSystem.getRankImage(rankLevel);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFFDE3344),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(proData['email'] ?? ''),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Image.asset(rankImage, width: 20, height: 20),
                                  SizedBox(width: 4),
                                  Text(
                                    rankName,
                                    style: TextStyle(
                                      color: rankColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    rating > 0
                                        ? rating.toStringAsFixed(1)
                                        : 'Novo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (ratingCount > 0)
                                    Text(
                                      ' ($ratingCount avaliações)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
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
                              backgroundColor: Color(0xFFDE3344),
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
    controller.selectedLocation.value = null;

    // Auto-fetch location
    controller.getCurrentLocation();

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
                SizedBox(height: 16),
                Obx(() {
                  final loc = controller.selectedLocation.value;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Get.to(
                                  () => LocationPickerView(
                                    initialLocation:
                                        controller.selectedLocation.value,
                                  ),
                                );
                                if (result != null && result is LatLng) {
                                  controller.selectedLocation.value = result;
                                }
                              },
                              icon: Icon(Icons.map),
                              label: Text(
                                loc == null ? 'Abrir Mapa' : 'Alterar no Mapa',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: loc == null
                                    ? Colors.grey[200]
                                    : Colors.green[100],
                                foregroundColor: loc == null
                                    ? Colors.black87
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            onPressed: () => controller.getCurrentLocation(),
                            icon: Icon(Icons.my_location),
                            tooltip: 'Usar localização atual',
                            color: Color(0xFFDE3344),
                          ),
                        ],
                      ),
                      if (loc != null)
                        Text(
                          'Lat: ${loc.latitude.toStringAsFixed(4)}, Lng: ${loc.longitude.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  );
                }),
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
        return Color(0xFFDE3344);
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
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                margin: EdgeInsets.all(16),
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

  void _showRequestAdjustmentDialog(
    BuildContext context,
    ServiceRequestModel request,
    QuoteModel quote,
  ) {
    final reasonController = TextEditingController();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Solicitar Ajuste',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Descreva o que você gostaria de ajustar no orçamento (ex: valor, prazo, materiais).',
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mensagem para o profissional',
                  border: OutlineInputBorder(),
                  hintText: 'Olá, poderia fazer por R\$...',
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
                              if (reasonController.text.trim().isEmpty) {
                                Get.snackbar(
                                  'Atenção',
                                  'Por favor, digite uma mensagem.',
                                );
                                return;
                              }
                              controller.requestQuoteAdjustment(
                                request,
                                quote,
                                reasonController.text,
                              );
                            },
                      child: controller.isLoading.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Enviar Solicitação'),
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

  void _showRejectQuoteDialog(
    BuildContext context,
    ServiceRequestModel request,
    QuoteModel quote,
  ) {
    String? selectedReason;
    final otherReasonController = TextEditingController();
    final reasons = [
      'Preço alto',
      'Prazo longo',
      'Escopo não atende',
      'Contratei outro profissional',
      'Outro',
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Recusar Orçamento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Por favor, selecione o motivo da recusa:',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                    ...reasons.map(
                      (reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                      ),
                    ),
                    if (selectedReason == 'Outro') ...[
                      SizedBox(height: 8),
                      TextField(
                        controller: otherReasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Descreva o motivo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
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
                                    if (selectedReason == null) {
                                      Get.snackbar(
                                        'Atenção',
                                        'Selecione um motivo.',
                                      );
                                      return;
                                    }
                                    String finalReason = selectedReason!;
                                    if (selectedReason == 'Outro') {
                                      if (otherReasonController.text
                                          .trim()
                                          .isEmpty) {
                                        Get.snackbar(
                                          'Atenção',
                                          'Descreva o motivo.',
                                        );
                                        return;
                                      }
                                      finalReason = otherReasonController.text
                                          .trim();
                                    }

                                    controller.rejectQuote(
                                      request,
                                      quote,
                                      finalReason,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
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
                                : Text('Confirmar Recusa'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAcceptQuoteDialog(
    BuildContext context,
    ServiceRequestModel request,
    QuoteModel quote,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Aceitar Orçamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você deseja aceitar este orçamento?'),
            SizedBox(height: 16),
            Text(
              'Profissional: ${quote.professionalName}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Valor: R\$ ${quote.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Ao aceitar, o status do pedido mudará para "Aceito" e você poderá conversar com o profissional.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancelar')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      controller.acceptQuote(request, quote);
                    },
              child: controller.isLoading.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Confirmar'),
            ),
          ),
        ],
      ),
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

class _ClientHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.currentUser.value;
      if (user == null) return SizedBox();

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDE3344), Color(0xFFFF6B6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Get.toNamed(Routes.PROFILE),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            ' ${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${user.coins ?? 0}',
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
          ],
        ),
      );
    });
  }
}
