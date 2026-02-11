import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/payment_secrets.dart';

class PaymentService {
  // Access Token movido para lib/config/payment_secrets.dart

  Future<String?> createPreference({
    required String title,
    required double price,
    required int quantity,
    required String email,
  }) async {
    final accessToken = PaymentSecrets.accessToken;

    if (accessToken == 'YOUR_ACCESS_TOKEN_HERE' || accessToken.isEmpty) {
      print('ERRO: Access Token do Mercado Pago não configurado.');
      return null;
    }

    final url = Uri.parse('https://api.mercadopago.com/checkout/preferences');

    final body = {
      "items": [
        {
          "title": title,
          "quantity": quantity,
          "currency_id": "BRL",
          "unit_price": price,
        },
      ],
      "payer": {"email": email},
      "binary_mode": true,

      "payment_methods": {
        "payment_method_id": "pix",
        "installments": 6,
        "excluded_payment_types": [
          {"id": "ticket"},
        ],
      },
      "statement_descriptor": "SAMURAIJOB",
      "back_urls": {
        "success": "samuraisjob://payment-success",
        "failure": "samuraisjob://payment-failure",
        "pending": "samuraisjob://payment-pending",
      },
      "auto_return": "approved",
    };

    try {
      print('Enviando requisição para Mercado Pago...');
      print(
        'Token (final 4): ...${accessToken.trim().substring(accessToken.length - 4)}',
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${accessToken.trim()}",
        },
        body: jsonEncode(body),
      );

      print('Status Code Mercado Pago: ${response.statusCode}');
      print('Response Body Mercado Pago: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Preferência criada com sucesso
        // Retorna init_point (Produção) ou sandbox_init_point (Testes)
        return data['init_point'];
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Erro desconhecido no Mercado Pago';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erro ao criar preferência: $e');
      rethrow; // Repassa o erro para o controller tratar
    }
  }
}
