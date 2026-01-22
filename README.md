# Samurais Job

Marketplace de serviços conectando clientes e profissionais.

## Arquitetura
- **Framework**: Flutter
- **Gerenciamento de Estado**: GetX
- **Backend**: Firebase (Auth, Firestore, Storage, Functions)
- **Pagamentos**: Mercado Pago (em breve)

## Estrutura de Pastas
- `lib/modules`: Contém os módulos da aplicação (Auth, Client, Professional, Admin, Moderator)
- `lib/routes`: Definição de rotas e navegação
- `lib/models`: Modelos de dados
- `lib/services`: Serviços globais

## Como rodar
1. Configure o Firebase:
   ```bash
   dart pub global run flutterfire_cli:flutterfire configure
   ```
2. Execute o app:
   ```bash
   flutter run
   ```
