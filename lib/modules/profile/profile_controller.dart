import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../modules/auth/auth_controller.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import '../../models/catalog_service_model.dart';

class ProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController rgController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController addressNumberController = TextEditingController();
  final TextEditingController addressStateController = TextEditingController();
  final TextEditingController skillController =
      TextEditingController(); // For adding new skills

  RxList<String> skills = <String>[].obs;
  Rx<File?> selectedImage = Rx<File?>(null);
  RxBool isLoading = false.obs;

  // Dynamic Catalog Data for Skills
  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);

  RxList<SubcategoryModel> subcategories = <SubcategoryModel>[].obs;
  Rx<SubcategoryModel?> selectedSubcategory = Rx<SubcategoryModel?>(null);

  RxList<CatalogServiceModel> services = <CatalogServiceModel>[].obs;
  Rx<CatalogServiceModel?> selectedService = Rx<CatalogServiceModel?>(null);

  RxBool isLoadingCatalog = false.obs;

  Rx<UserModel?> get user => _authController.currentUser;

  @override
  void onInit() {
    super.onInit();
    // Increase upload timeout to avoid premature cancellation on slow connections
    _storage.setMaxUploadRetryTime(Duration(minutes: 5));
    _loadUserData();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoadingCatalog.value = true;
      final snapshot = await _db.collection('categories').orderBy('nome').get();
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
      selectedService.value = null;

      final snapshot = await _db
          .collection('subcategories')
          .where('categoria_id', isEqualTo: categoryId)
          .get();

      subcategories.value = snapshot.docs
          .map((doc) => SubcategoryModel.fromMap(doc.data(), doc.id))
          .toList();

      subcategories.sort((a, b) => a.name.compareTo(b.name));
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
      selectedService.value = null;

      final snapshot = await _db
          .collection('services')
          .where('subcategoria_id', isEqualTo: subcategoryId)
          .where('ativo', isEqualTo: true)
          .get();

      services.value = snapshot.docs
          .map((doc) => CatalogServiceModel.fromMap(doc.data(), doc.id))
          .toList();

      services.sort((a, b) => a.name.compareTo(b.name));
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
      selectedService.value = null;
    }
  }

  void onSubcategorySelected(SubcategoryModel? subcategory) {
    selectedSubcategory.value = subcategory;
    if (subcategory != null) {
      fetchServices(subcategory.id);
    } else {
      services.clear();
      selectedService.value = null;
    }
  }

  void onServiceSelected(CatalogServiceModel? service) {
    selectedService.value = service;
  }

  void _loadUserData() {
    final currentUser = user.value;
    if (currentUser != null) {
      nameController.text = currentUser.name;
      phoneController.text = currentUser.phone ?? '';
      cpfController.text = currentUser.cpf ?? '';
      rgController.text = currentUser.rg ?? '';
      bioController.text = currentUser.bio ?? '';
      addressController.text = currentUser.address ?? '';
      cepController.text = currentUser.cep ?? '';
      addressNumberController.text = currentUser.addressNumber ?? '';
      addressStateController.text = currentUser.addressState ?? '';
      skills.value = List.from(currentUser.skills ?? []);
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Reduced size for Base64 compatibility
        maxHeight: 512,
        imageQuality: 70, // Reduced quality for Base64 compatibility
      );
      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível selecionar a imagem: $e');
    }
  }

  void addSkill() {
    if (skills.length >= 5) {
      Get.snackbar(
        'Limite Atingido',
        'Você só pode adicionar até 5 habilidades.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final skill = skillController.text.trim();
    if (skill.isNotEmpty && !skills.contains(skill)) {
      skills.add(skill);
      skillController.clear();
    }
  }

  void addCatalogSkill(String skillName) {
    if (skills.length >= 5) {
      Get.snackbar(
        'Limite Atingido',
        'Você só pode adicionar até 5 habilidades.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (!skills.contains(skillName)) {
      skills.add(skillName);
      Get.back(); // Close bottom sheet if open
      Get.snackbar(
        'Sucesso',
        'Habilidade "$skillName" adicionada!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Aviso',
        'Você já possui esta habilidade.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void removeSkill(String skill) {
    skills.remove(skill);
  }

  Future<void> saveProfile() async {
    final currentUser = user.value;
    if (currentUser == null) return;

    // Verificar se o usuário está autenticado no Firebase Auth
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      Get.snackbar(
        'Erro',
        'Sessão expirada. Por favor, faça login novamente.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      String? avatarUrl = currentUser.avatarUrl;

      // Upload Image if selected
      if (selectedImage.value != null) {
        if (!await selectedImage.value!.exists()) {
          throw Exception('Arquivo de imagem não encontrado no dispositivo');
        }

        // Tenta fazer o upload para o Storage primeiro
        try {
          final ref = _storage.ref().child('avatars/${currentUser.id}.jpg');
          print('DEBUG: Tentando upload para Firebase Storage...');

          final metadata = SettableMetadata(contentType: 'image/jpeg');
          final taskSnapshot = await ref.putFile(
            selectedImage.value!,
            metadata,
          );

          if (taskSnapshot.state == TaskState.success) {
            avatarUrl = await taskSnapshot.ref.getDownloadURL();
            print('DEBUG: Upload via Storage com sucesso! URL: $avatarUrl');
          } else {
            throw Exception(
              'Estado do upload não é sucesso: ${taskSnapshot.state}',
            );
          }
        } catch (e) {
          print(
            'DEBUG: Falha no Storage ($e). Tentando fallback para Base64...',
          );

          // Fallback: Converter para Base64 e salvar como string
          // Nota: Firestore tem limite de 1MB por documento.
          // Com maxWidth 512 e quality 70, a imagem deve ficar < 50KB.
          final bytes = await selectedImage.value!.readAsBytes();
          final base64Image = base64Encode(bytes);
          avatarUrl = 'data:image/jpeg;base64,$base64Image';

          print(
            'DEBUG: Imagem convertida para Base64 (Tamanho: ${base64Image.length} chars).',
          );

          Get.snackbar(
            'Aviso',
            'Problema no Storage detectado. Salvando imagem diretamente no banco de dados (Modo Offline/Fallback).',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: Duration(seconds: 5),
          );
        }
      }

      // Update Firestore
      await _db.collection('users').doc(currentUser.id).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'cpf': cpfController.text.trim(),
        'rg': rgController.text.trim(),
        'bio': bioController.text.trim(),
        'address': addressController.text.trim(),
        'cep': cepController.text.trim(),
        'addressNumber': addressNumberController.text.trim(),
        'addressState': addressStateController.text.trim(),
        'skills': skills.toList(),
        'avatarUrl': avatarUrl,
      });

      // Update Local State
      currentUser.name = nameController.text.trim();
      currentUser.phone = phoneController.text.trim();
      currentUser.cpf = cpfController.text.trim();
      currentUser.rg = rgController.text.trim();
      currentUser.bio = bioController.text.trim();
      currentUser.address = addressController.text.trim();
      currentUser.cep = cepController.text.trim();
      currentUser.addressNumber = addressNumberController.text.trim();
      currentUser.addressState = addressStateController.text.trim();
      currentUser.skills = skills.toList();
      currentUser.avatarUrl = avatarUrl;

      selectedImage.value = null; // Clear selected image

      _authController.currentUser.refresh();

      Get.back();
      Get.snackbar(
        'Sucesso',
        'Perfil atualizado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar perfil: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
