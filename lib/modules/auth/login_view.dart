import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class LoginView extends GetView<AuthController> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final RxBool isObscure = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/samurais_job_logo.png',
                height: 180,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  );
                },
              ),
              SizedBox(height: 40),
              Text(
                'Bem-vindo de volta!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Faça login para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'exemplo@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFDE3344), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              SizedBox(height: 16),
              Obx(
                () => TextField(
                  controller: passwordCtrl,
                  obscureText: isObscure.value,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => isObscure.toggle(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFDE3344),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Obx(
                () => controller.isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFDE3344),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          controller.login(emailCtrl.text, passwordCtrl.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDE3344),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text('ENTRAR'),
                      ),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog(context),
                  child: Text(
                    'Esqueci minha senha',
                    style: TextStyle(
                      color: Color(0xFFDE3344),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Não tem uma conta?',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.toNamed('/register');
                    },
                    child: Text(
                      'Cadastre-se',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDE3344),
                      ),
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

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailCtrl = TextEditingController();
    if (emailCtrl.text.isNotEmpty) {
      resetEmailCtrl.text = emailCtrl.text;
    }

    Get.dialog(
      AlertDialog(
        title: Text('Recuperar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Digite seu email para receber o link de recuperação.'),
            SizedBox(height: 16),
            TextField(
              controller: resetEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              controller.resetPassword(resetEmailCtrl.text.trim());
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDE3344),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Enviar'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
