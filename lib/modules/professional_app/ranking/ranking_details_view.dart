import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/auth_controller.dart';
import '../../../utils/ranking_system.dart';

class RankingDetailsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Ranking Samurai')),
        body: Center(child: Text('Usuário não encontrado')),
      );
    }

    final rankLevel = RankingSystem.calculateRank(
      user.completedServicesCount,
      user.rating,
      user.cancellationCount,
    );

    final rankName = RankingSystem.getRankName(rankLevel);
    final rankIcon = RankingSystem.getRankIcon(rankLevel);
    final rankColor = RankingSystem.getRankColor(rankLevel);
    final rankQuote = RankingSystem.getRankQuote(rankLevel);
    final rankImage = RankingSystem.getRankImage(rankLevel);

    final progress = RankingSystem.getNextLevelProgress(
      user.completedServicesCount,
      user.rating,
    );

    final nextLevelReq = RankingSystem.getNextLevelRequirement(
      user.completedServicesCount,
      user.rating,
      user.cancellationCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Caminho do Samurai'),
        centerTitle: true,
        backgroundColor: Color(0xFFDE3344),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Current Level Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.dialog(
                        Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InteractiveViewer(
                                panEnabled: true,
                                boundaryMargin: EdgeInsets.all(20),
                                minScale: 0.5,
                                maxScale: 4,
                                child: Image.asset(
                                  rankImage,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => Get.back(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: rankColor, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: AssetImage(rankImage),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nível Atual',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    rankName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDE3344),
                    ),
                  ),
                  SizedBox(height: 8),

                  Text(
                    rankQuote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Progress Section
            Text(
              'Progresso para ${nextLevelReq['next']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 20,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(rankColor),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% Concluído',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 32),

            // Next Objectives
            if (nextLevelReq['next'] != 'Máximo') ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Próximo Objetivo:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDE3344),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildRequirementRow(
                      icon: Icons.work,
                      label: 'Serviços Realizados',
                      current: user.completedServicesCount.toString(),
                      target: nextLevelReq['services'].toString(),
                      isMet:
                          user.completedServicesCount >=
                          (nextLevelReq['services'] as int),
                    ),
                    Divider(),
                    _buildRequirementRow(
                      icon: Icons.star,
                      label: 'Avaliação Média',
                      current: user.rating.toStringAsFixed(1),
                      target: (nextLevelReq['rating'] as double)
                          .toStringAsFixed(1),
                      isMet: user.rating >= (nextLevelReq['rating'] as double),
                    ),
                    if (nextLevelReq['cancellations'] != null) ...[
                      Divider(),
                      _buildRequirementRow(
                        icon: Icons.cancel_presentation,
                        label: 'Máx. Cancelamentos',
                        current: user.cancellationCount.toString(),
                        target: nextLevelReq['cancellations'].toString(),
                        isMet:
                            user.cancellationCount <=
                            (nextLevelReq['cancellations'] as int),
                        isInverted: true,
                      ),
                    ],
                  ],
                ),
              ),
            ] else
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Você alcançou o nível máximo! Mantenha sua honra e excelência.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow({
    required IconData icon,
    required String label,
    required String current,
    required String target,
    required bool isMet,
    bool isInverted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  isInverted
                      ? 'Atual: $current (Máximo: $target)'
                      : 'Atual: $current / Meta: $target',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
