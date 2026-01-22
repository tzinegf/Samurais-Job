import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_model.dart';
import 'auth_controller.dart';

class RegisterController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  final RxString selectedRole = 'client'.obs;
  final RxList<String> selectedSkills = <String>[].obs;
  
  final List<String> availableSkills = [
    'Marceneiro',
    'Encanador',
    'Pedreiro',
    'Eletricista',
    'Pintor',
    'Jardinagem',
    'Limpeza',
    'Mecânico',
    'Informática',
    'Montador de Móveis',
    'Costureira',
    'Cozinheiro',
  ];

  void toggleSkill(String skill) {
    if (selectedSkills.contains(skill)) {
      selectedSkills.remove(skill);
    } else {
      if (selectedSkills.length < 3) {
        selectedSkills.add(skill);
      } else {
        Get.snackbar("Limite atingido", "Máximo de 3 habilidades permitidas.");
      }
    }
  }

  void register() {
    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
      Get.snackbar("Erro", "Preencha todos os campos obrigatórios.");
      return;
    }

    if (selectedRole.value == 'professional' && selectedSkills.isEmpty) {
      Get.snackbar("Erro", "Selecione pelo menos uma habilidade.");
      return;
    }

    UserModel newUser = UserModel(
      email: emailCtrl.text.trim(),
      name: nameCtrl.text.trim(),
      role: selectedRole.value,
      phone: phoneCtrl.text.trim(),
      skills: selectedRole.value == 'professional' ? selectedSkills.toList() : null,
      bio: selectedRole.value == 'professional' ? bioCtrl.text.trim() : null,
      coins: 0,
      points: 0,
      level: 'Bronze',
    );

    _authController.registerUser(newUser, passwordCtrl.text);
  }
}
