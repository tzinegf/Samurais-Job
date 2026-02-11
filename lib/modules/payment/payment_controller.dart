import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
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
        // 2. Launch Checkout using Custom Tabs
        try {
          await launchUrl(
            Uri.parse(initPoint),
            customTabsOptions: CustomTabsOptions(
              colorSchemes: CustomTabsColorSchemes.defaults(
                toolbarColor: Color(0xFFDE3344),
              ),
              shareState: CustomTabsShareState.on,
              urlBarHidingEnabled: true,
              showTitle: true,
              closeButton: CustomTabsCloseButton(
                icon: CustomTabsCloseButtonIcons.back,
              ),
            ),
            safariVCOptions: SafariViewControllerOptions(
              preferredBarTintColor: Color(0xFFDE3344),
              preferredControlTintColor: Colors.white,
              barCollapsingEnabled: true,
              entersReaderIfAvailable: false,
              dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
            ),
          );

          // 3. Show confirmation dialog
          Get.defaultDialog(
            title: "Pagamento em Processamento",
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Após concluir o pagamento, clique em 'Confirmar' para validar suas moedas.",
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
        } catch (e) {
          print("Erro ao abrir Custom Tab: $e");
          // Fallback para navegador padrão se Custom Tabs falhar
          final uri = Uri.parse(initPoint);
          if (await url_launcher.canLaunchUrl(uri)) {
            await url_launcher.launchUrl(
              uri,
              mode: url_launcher.LaunchMode.externalApplication,
            );
          } else {
            Get.snackbar('Erro', 'Não foi possível abrir o pagamento.');
          }
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
