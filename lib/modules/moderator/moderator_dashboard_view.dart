import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/auth_controller.dart';

class ModeratorDashboardView extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Painel Moderador')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bem-vindo, Moderador!'),
            ElevatedButton(onPressed: () => controller.logout(), child: Text('Sair'))
          ],
        ),
      ),
    );
  }
}
