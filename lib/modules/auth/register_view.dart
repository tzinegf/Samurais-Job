import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Criar Nova Conta')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller.nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nome Completo',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text('Tipo de Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Obx(() => Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Cliente'),
                    value: 'client',
                    groupValue: controller.selectedRole.value,
                    onChanged: (val) => controller.selectedRole.value = val!,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Profissional'),
                    value: 'professional',
                    groupValue: controller.selectedRole.value,
                    onChanged: (val) => controller.selectedRole.value = val!,
                  ),
                ),
              ],
            )),
            
            // Professional fields
            Obx(() {
              if (controller.selectedRole.value == 'professional') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(),
                    Text('Informações Profissionais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: controller.bioCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Sobre você (Bio)',
                        border: OutlineInputBorder(),
                        hintText: 'Descreva sua experiência e serviços...',
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('Selecione suas habilidades (Máx 3):', style: TextStyle(fontWeight: FontWeight.w500)),
                    Wrap(
                      spacing: 8.0,
                      children: controller.availableSkills.map((skill) {
                        return ChoiceChip(
                          label: Text(skill),
                          selected: controller.selectedSkills.contains(skill),
                          onSelected: (selected) {
                            controller.toggleSkill(skill);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                );
              } else {
                return SizedBox.shrink();
              }
            }),

            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.register(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('CRIAR CONTA'),
            ),
          ],
        ),
      ),
    );
  }
}
