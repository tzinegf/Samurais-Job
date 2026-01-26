import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'professional_settings_controller.dart';

class ProfessionalSettingsView extends GetView<ProfessionalSettingsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        backgroundColor: Color(0xFFDE3344),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Preferências'),
          Obx(() => SwitchListTile(
                title: Text('Notificações'),
                subtitle: Text('Receber alertas de novos serviços'),
                value: controller.notificationsEnabled.value,
                onChanged: controller.toggleNotifications,
                activeColor: Color(0xFFDE3344),
              )),
          Divider(),
          _buildSectionHeader('Serviços'),
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Raio de Atendimento: ${controller.serviceRadius.value.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Slider(
                    value: controller.serviceRadius.value,
                    min: 1.0,
                    max: 100.0,
                    divisions: 99,
                    label: '${controller.serviceRadius.value.round()} km',
                    activeColor: Color(0xFFDE3344),
                    onChanged: controller.updateServiceRadius,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Defina a distância máxima para receber solicitações de serviço.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              )),
          Divider(),
          _buildSectionHeader('Sobre'),
          ListTile(
            title: Text('Versão do App'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info_outline),
          ),
          ListTile(
            title: Text('Termos de Uso'),
            leading: Icon(Icons.description_outlined),
            onTap: () {
              // TODO: Navigate to Terms
            },
          ),
          ListTile(
            title: Text('Política de Privacidade'),
            leading: Icon(Icons.privacy_tip_outlined),
            onTap: () {
              // TODO: Navigate to Privacy Policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFFDE3344),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
