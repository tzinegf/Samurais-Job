import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/payment_service.dart';
import '../auth/auth_controller.dart';

class PaymentController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();

  RxBool isLoading = false.obs;

  Future<void> addCoins(int amount) async {
    try {
      final user = _authController.currentUser.value;
      if (user == null) return;

      await _db.collection('users').doc(user.id).update({
        'coins': FieldValue.increment(amount),
      });

      // Local update
      user.coins = (user.coins ?? 0) + amount;
      _authController.currentUser.refresh();

      Get.snackbar('Moedas Adicionadas', 'Você recebeu $amount moedas!');
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao adicionar moedas: $e');
    }
  }

  Future<void> buyCoins(int coins, double price) async {
    try {
      final user = _authController.currentUser.value;
      if (user == null) return;

      isLoading.value = true;

      // 1. Create Preference in Mercado Pago
      final initPoint = await _paymentService.createPreference(
        title: 'Pacote de $coins Moedas',
        price: price,
        quantity: 1,
        email: user.email,
      );

      if (initPoint != null) {
        // 2. Launch Checkout
        final uri = Uri.parse(initPoint);

        bool launched = false;
        try {
          // Force external application (Browser) which is best for Payments
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } on PlatformException catch (e) {
          print("Erro de Plataforma (Plugin): $e");
          Get.defaultDialog(
            title: "Erro de Configuração",
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "O plugin de navegação não está respondendo corretamente.\n\nIsso geralmente acontece após atualizações. Por favor, reinicie o aplicativo (pare e execute novamente).",
                textAlign: TextAlign.center,
              ),
            ),
            textConfirm: "OK",
            confirmTextColor: Colors.white,
            onConfirm: () => Get.back(),
          );
          isLoading.value = false;
          return;
        } catch (e) {
          print("Erro ao lançar URL: $e");
          // Try platform default as last resort
          try {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (e2) {
            print("Erro fallback URL: $e2");
          }
        }

        if (launched) {
          // 3. Temporarily show a dialog to confirm manual check
          Get.defaultDialog(
            title: "Pagamento em Processamento",
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Você será redirecionado para o Mercado Pago.\n\nApós concluir o pagamento, clique em 'Confirmar' para validar suas moedas.",
                textAlign: TextAlign.center,
              ),
            ),
            textConfirm: "Já paguei",
            textCancel: "Cancelar",
            confirmTextColor: Colors.white,
            buttonColor: Color(0xFFDE3344),
            cancelTextColor: Color(0xFFDE3344),
            onConfirm: () async {
              Get.back(); // Close dialog
              await addCoins(coins);
            },
          );
        } else {
          Get.snackbar('Erro', 'Não foi possível abrir o link de pagamento.');
        }
      }
    } catch (e) {
      // Clean up error message
      String message = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Erro no Pagamento',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
