import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'payment_controller.dart';

class BuyCoinsView extends GetView<PaymentController> {
  final List<Map<String, dynamic>> packages = [
    {'coins': 10, 'price': 10.00, 'label': 'Pacote Básico'},
    {
      'coins': 50,
      'price': 45.00,
      'label': 'Pacote Popular',
      'badge': '10% OFF',
    },
    {
      'coins': 100,
      'price': 80.00,
      'label': 'Pacote Premium',
      'badge': '20% OFF',
    },
    {
      'coins': 500,
      'price': 350.00,
      'label': 'Pacote Profissional',
      'badge': '30% OFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comprar Moedas')),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                  title: Text(
                    pkg['label'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${pkg['coins']} Moedas',
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _confirmPurchase(context, pkg),
                    child: Text('R\$ ${pkg['price'].toStringAsFixed(2)}'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      backgroundColor: Color(0xFFDE3344),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (pkg.containsKey('badge'))
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFDE3344),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        pkg['badge'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmPurchase(BuildContext context, Map<String, dynamic> pkg) {
    Get.defaultDialog(
      title: 'Confirmar Compra',
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.shopping_cart, size: 48, color: Color(0xFFDE3344)),
            SizedBox(height: 16),
            Text(
              'Você está comprando ${pkg['coins']} moedas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Total: R\$ ${pkg['price'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Simulação de pagamento via Mercado Pago',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      textConfirm: 'Pagar Agora',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      buttonColor: Color(0xFFDE3344),
      cancelTextColor: Colors.red,
      onConfirm: () {
        Get.back(); // Close dialog
        controller.buyCoins(pkg['coins'], pkg['price']);
      },
    );
  }
}
