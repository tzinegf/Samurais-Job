import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  // TODO: Crie uma conta no Mercado Pago Developers e pegue seu Access Token de Teste:
  // https://www.mercadopago.com.br/developers/panel
  static const String ACCESS_TOKEN =
      'APP_USR-1657234746865481-012314-0aa90914870337a9a801f9611f6c33ef-3154275773';

  Future<String?> createPreference({
    required String title,
    required double price,
    required int quantity,
    required String email,
  }) async {
    if (ACCESS_TOKEN == 'YOUR_ACCESS_TOKEN_HERE') {
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
        'Token (final 4): ...${ACCESS_TOKEN.trim().substring(ACCESS_TOKEN.length - 4)}',
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${ACCESS_TOKEN.trim()}",
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
