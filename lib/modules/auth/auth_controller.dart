import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Rxn<User> firebaseUser = Rxn<User>();
  Rxn<UserModel> currentUser = Rxn<UserModel>();
  RxBool isLoading = false.obs;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void onReady() {
    super.onReady();
    // Uncomment these lines when Firebase is configured
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }

  _setInitialScreen(User? user) async {
    _userSubscription?.cancel();

    if (user == null) {
      currentUser.value = null;
      // Prevent redirect loop if already on login, register or splash page
      if (Get.currentRoute == Routes.REGISTER ||
          Get.currentRoute == Routes.LOGIN ||
          Get.currentRoute == Routes.SPLASH) {
        return;
      }
      Get.offAllNamed(Routes.LOGIN);
    } else {
      try {
        DocumentSnapshot doc = await _db
            .collection('users')
            .doc(user.uid)
            .get();

        // Retry logic for registration race condition
        if (!doc.exists) {
          await Future.delayed(Duration(seconds: 2));
          doc = await _db.collection('users').doc(user.uid).get();
        }

        if (doc.exists) {
          currentUser.value = UserModel.fromDocument(doc); // Store user data

          // Start listening to real-time updates
          _userSubscription = _db
              .collection('users')
              .doc(user.uid)
              .snapshots()
              .listen((snapshot) {
            if (snapshot.exists) {
              currentUser.value = UserModel.fromDocument(snapshot);
            }
          });

          // If on splash, don't redirect yet
          if (Get.currentRoute == Routes.SPLASH) return;

          redirectUser();
        } else {
          // Se o documento não existe mas estamos na tela de registro,
          // não redirecionar para Login, pois o registerUser fará isso.
          if (Get.currentRoute == Routes.REGISTER) return;

          Get.snackbar(
            "Erro",
            "Perfil de usuário não encontrado no banco de dados.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          await _auth.signOut();
          Get.offAllNamed(Routes.LOGIN);
        }
      } catch (e) {
        // If error (e.g. offline), stay on login or show error
        print("Auth Check Error: $e");
      }
    }
  }

  void redirectUser() async {
    if (currentUser.value == null) return;
    String role = currentUser.value!.role;
    switch (role) {
      case 'client':
        Get.offAllNamed(Routes.DASHBOARD_CLIENT);
        break;
      case 'professional':
        Get.offAllNamed(Routes.DASHBOARD_PROFESSIONAL);
        break;
      case 'admin':
        Get.offAllNamed(Routes.DASHBOARD_ADMIN);
        break;
      case 'moderator':
        Get.offAllNamed(Routes.DASHBOARD_MODERATOR);
        break;
      default:
        Get.snackbar(
          "Erro",
          "Papel de usuário desconhecido.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        await _auth.signOut();
        Get.offAllNamed(Routes.LOGIN);
    }
  }

  void login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      Get.snackbar(
        "Erro no Login",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      Get.snackbar(
        "Atenção",
        "Por favor, informe seu email.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        "Sucesso",
        "Email de recuperação enviado para $email",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Erro",
        "Falha ao enviar email de recuperação: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void logout() async {
    await _auth.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }

  void registerUser(UserModel userModel, String password) async {
    try {
      // Check admin/moderator restrictions
      if ((userModel.role == 'admin' || userModel.role == 'moderator')) {
        if (userModel.email != 'eg_f1@hotmail.com') {
          Get.snackbar(
            "Erro",
            "Apenas o administrador master pode criar contas de admin/moderador.",
          );
          return;
        }
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: password,
      );

      userModel.id = cred.user!.uid;

      // Update local currentUser immediately
      currentUser.value = userModel;

      await _db.collection('users').doc(cred.user!.uid).set(userModel.toJson());

      Get.snackbar("Sucesso", "Conta criada com sucesso!");

      // Navegação manual pois o listener foi suprimido na tela de registro
      switch (userModel.role) {
        case 'client':
          Get.offAllNamed(Routes.DASHBOARD_CLIENT);
          break;
        case 'professional':
          Get.offAllNamed(Routes.DASHBOARD_PROFESSIONAL);
          break;
        case 'admin':
          Get.offAllNamed(Routes.DASHBOARD_ADMIN);
          break;
        case 'moderator':
          Get.offAllNamed(Routes.DASHBOARD_MODERATOR);
          break;
        default:
          Get.offAllNamed(Routes.LOGIN);
      }
    } catch (e) {
      Get.snackbar(
        "Erro no Registro",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
