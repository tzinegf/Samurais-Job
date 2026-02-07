import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import '../../models/catalog_service_model.dart';
import 'auth_controller.dart';

class RegisterController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  final RxString selectedRole = 'professional'.obs;
  final RxList<String> selectedSkills = <String>[].obs;

  // Catalog Data
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<SubcategoryModel> subcategories = <SubcategoryModel>[].obs;
  final RxList<CatalogServiceModel> services = <CatalogServiceModel>[].obs;

  final Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);
  final Rx<SubcategoryModel?> selectedSubcategory = Rx<SubcategoryModel?>(null);

  final isLoadingCatalog = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoadingCatalog.value = true;
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      categories.value = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      isLoadingCatalog.value = false;
    }
  }

  Future<void> fetchSubcategories(String categoryId) async {
    try {
      isLoadingCatalog.value = true;
      subcategories.clear();
      services.clear();
      selectedSubcategory.value = null;
      selectedSkills.clear();

      final snapshot = await FirebaseFirestore.instance
          .collection('subcategories')
          .where('categoria_id', isEqualTo: categoryId)
          .get();

      subcategories.value = snapshot.docs
          .map((doc) => SubcategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching subcategories: $e');
    } finally {
      isLoadingCatalog.value = false;
    }
  }

  Future<void> fetchServices(String subcategoryId) async {
    try {
      isLoadingCatalog.value = true;
      services.clear();
      selectedSkills.clear();

      final snapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('subcategoria_id', isEqualTo: subcategoryId)
          .where('ativo', isEqualTo: true)
          .get();

      services.value = snapshot.docs
          .map((doc) => CatalogServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching services: $e');
    } finally {
      isLoadingCatalog.value = false;
    }
  }

  void onCategorySelected(CategoryModel? category) {
    selectedCategory.value = category;
    if (category != null) {
      fetchSubcategories(category.id);
    } else {
      subcategories.clear();
      services.clear();
      selectedSubcategory.value = null;
      selectedSkills.clear();
    }
  }

  void onSubcategorySelected(SubcategoryModel? subcategory) {
    selectedSubcategory.value = subcategory;
    if (subcategory != null) {
      fetchServices(subcategory.id);
    } else {
      services.clear();
      selectedSkills.clear();
    }
  }

  void toggleSkill(String skill) {
    if (selectedSkills.contains(skill)) {
      selectedSkills.remove(skill);
    } else {
      if (selectedSkills.length < 5) {
        selectedSkills.add(skill);
      } else {
        Get.snackbar(
          "Limite atingido",
          "Máximo de 5 habilidades permitidas.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }

  void register() {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty) {
      Get.snackbar("Erro", "Preencha todos os campos obrigatórios.");
      return;
    }

    if (selectedSkills.isEmpty) {
      Get.snackbar("Erro", "Selecione pelo menos uma habilidade.");
      return;
    }
    if (selectedCategory.value == null || selectedSubcategory.value == null) {
      Get.snackbar(
        "Erro",
        "Selecione uma categoria e subcategoria.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    UserModel newUser = UserModel(
      email: emailCtrl.text.trim(),
      name: nameCtrl.text.trim(),
      role: selectedRole.value,
      phone: phoneCtrl.text.trim(),
      skills: selectedSkills.toList(),
      bio: null,
      coins: 0,
      rating: 3.0,
    );

    _authController.registerUser(newUser, passwordCtrl.text);
  }
}
