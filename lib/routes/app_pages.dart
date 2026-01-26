import 'package:get/get.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_view.dart';
import '../modules/auth/register_view.dart';
import '../modules/client_app/client/client_dashboard_view.dart';
import '../modules/professional_app/professional/professional_dashboard_view.dart';
import '../modules/admin/admin_dashboard_view.dart';
import '../modules/moderator/moderator_dashboard_view.dart';
import '../modules/professional_app/professional/professional_binding.dart';
import '../modules/client_app/client/client_binding.dart';
import '../modules/auth/register_binding.dart';
import '../modules/chat/chat_binding.dart';
import '../modules/chat/chat_view.dart';
import '../modules/history/history_binding.dart';
import '../modules/history/history_view.dart';
import '../modules/payment/buy_coins_view.dart';
import '../modules/payment/payment_controller.dart';
import '../modules/profile/profile_view.dart';
import '../modules/profile/profile_controller.dart';
import '../modules/professional_app/professional/settings/professional_settings_view.dart';
import '../modules/professional_app/professional/settings/professional_settings_controller.dart';
import '../modules/manifesto/manifesto_view.dart';
import '../modules/splash/splash_view.dart';
import '../modules/splash/splash_controller.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => SplashView(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
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
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PaymentController());
      }),
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => ProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileController());
      }),
    ),
    GetPage(
      name: Routes.PROFESSIONAL_SETTINGS,
      page: () => ProfessionalSettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfessionalSettingsController());
      }),
    ),
    GetPage(name: Routes.MANIFESTO, page: () => ManifestoView()),
  ];
}
