import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'modules/auth/auth_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Run 'flutterfire configure' to generate firebase_options.dart and uncomment the following line
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    GetMaterialApp(
      title: "Samurais Job",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      initialBinding: AuthBinding(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    ),
  );
}
