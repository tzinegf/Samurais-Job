import 'package:get/get.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_view.dart';
import '../modules/auth/register_view.dart';
import '../modules/client/client_dashboard_view.dart';
import '../modules/professional/professional_dashboard_view.dart';
import '../modules/admin/admin_dashboard_view.dart';
import '../modules/moderator/moderator_dashboard_view.dart';
import '../modules/professional/professional_binding.dart';
import '../modules/client/client_binding.dart';
import '../modules/auth/register_binding.dart';
import '../modules/chat/chat_binding.dart';
import '../modules/chat/chat_view.dart';
import '../modules/history/history_binding.dart';
import '../modules/history/history_view.dart';
import '../modules/professional/buy_coins_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(name: Routes.LOGIN, page: () => LoginView()),
    GetPage(
      name: Routes.REGISTER,
      page: () => RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.DASHBOARD_CLIENT,
      page: () => ClientDashboardView(),
      binding: ClientBinding(),
    ),
    GetPage(
      name: Routes.DASHBOARD_PROFESSIONAL,
      page: () => ProfessionalDashboardView(),
      binding: ProfessionalBinding(),
    ),
    GetPage(name: Routes.DASHBOARD_ADMIN, page: () => AdminDashboardView()),
    GetPage(
      name: Routes.DASHBOARD_MODERATOR,
      page: () => ModeratorDashboardView(),
    ),
    GetPage(name: Routes.CHAT, page: () => ChatView(), binding: ChatBinding()),
    GetPage(
      name: Routes.HISTORY,
      page: () => HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: Routes.BUY_COINS,
      page: () => BuyCoinsView(),
      // ProfessionalController is already persistent or will be found if ProfessionalBinding was used before
      // But to be safe, we can use ProfessionalBinding or just rely on Get.find if it's alive.
      // Since we navigate from Dashboard where ProfessionalController is alive, it should be fine.
      // But if we want to be safe:
      // binding: ProfessionalBinding(),
      // However, ProfessionalBinding puts ProfessionalController.
      // If it's already there, GetX handles it.
    ),
  ];
}
