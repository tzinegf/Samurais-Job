import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Rxn<User> firebaseUser = Rxn<User>();
  Rxn<UserModel> currentUser = Rxn<UserModel>();
  RxBool isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    // Uncomment these lines when Firebase is configured
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? user) async {
    if (user == null) {
      // Prevent redirect loop if already on login or register page
      if (Get.currentRoute == Routes.REGISTER ||
          Get.currentRoute == Routes.LOGIN) {
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
          String role = doc['role'];
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
              Get.snackbar("Erro", "Papel de usuário desconhecido.");
              await _auth.signOut();
              Get.offAllNamed(Routes.LOGIN);
          }
        } else {
          // Se o documento não existe mas estamos na tela de registro,
          // não redirecionar para Login, pois o registerUser fará isso.
          if (Get.currentRoute == Routes.REGISTER) return;

          Get.snackbar(
            "Erro",
            "Perfil de usuário não encontrado no banco de dados.",
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

  void login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      Get.snackbar("Erro no Login", e.toString());
    } finally {
      isLoading.value = false;
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
      Get.snackbar("Erro no Registro", e.toString());
    }
  }
}
