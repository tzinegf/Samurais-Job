import 'package:flutter/material.dart';

class ManifestoView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manifesto Samurai'),
        backgroundColor: Color(0xFFDE3344),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              '🥋 MANIFESTO DOS SAMURAIS JOB',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDE3344),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              '''Em um mundo onde qualquer um pode prometer, 
poucos realmente cumprem. 

O Samurais JOB nasceu para mudar isso. 

Aqui, trabalho não é apenas serviço. 
É compromisso. 
É respeito pelo tempo, pelo dinheiro e pela confiança de quem contrata. 

Cada profissional que entra em nossa plataforma inicia como um Ronin. 
Sem títulos. 
Sem privilégios. 
Apenas com a oportunidade de provar seu valor. 

A evolução não vem de promessas, 
mas de ações: 
serviços bem feitos, avaliações honestas e comportamento justo. 

Honra se constrói. 
Reputação se conquista. 
Confiança se mantém. 

No Samurais JOB, clientes escolhem com segurança. 
Profissionais crescem com mérito. 
E todos sabem que o verdadeiro valor está no caminho percorrido. 

Samurais JOB. 
Onde o trabalho segue o código da honra.''',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: Color(0xFFDE3344).withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
