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

class ProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController skillController =
      TextEditingController(); // For adding new skills

  RxList<String> skills = <String>[].obs;
  Rx<File?> selectedImage = Rx<File?>(null);
  RxList<String> documentUrls = <String>[].obs;
  RxList<File> newDocuments = <File>[].obs;
  RxBool isLoading = false.obs;

  Rx<UserModel?> get user => _authController.currentUser;

  @override
  void onInit() {
    super.onInit();
    // Increase upload timeout to avoid premature cancellation on slow connections
    _storage.setMaxUploadRetryTime(Duration(minutes: 5));
    _loadUserData();
  }

  void _loadUserData() {
    final currentUser = user.value;
    if (currentUser != null) {
      nameController.text = currentUser.name;
      phoneController.text = currentUser.phone ?? '';
      bioController.text = currentUser.bio ?? '';
      addressController.text = currentUser.address ?? '';
      skills.value = List.from(currentUser.skills ?? []);
      documentUrls.value = List.from(currentUser.documents ?? []);
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

  Future<void> pickDocument() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        newDocuments.add(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível selecionar o documento: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void removeNewDocument(int index) {
    newDocuments.removeAt(index);
  }

  void removeExistingDocument(String url) {
    documentUrls.remove(url);
    // Note: We are not deleting from Storage/Firestore immediately,
    // only when saving. Or we could just remove from the list references.
  }

  void addSkill() {
    final skill = skillController.text.trim();
    if (skill.isNotEmpty && !skills.contains(skill)) {
      skills.add(skill);
      skillController.clear();
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

      // Upload New Documents
      List<String> finalDocumentUrls = List.from(documentUrls);

      for (var i = 0; i < newDocuments.length; i++) {
        File docFile = newDocuments[i];
        String docUrl;
        try {
          final String docId = '${DateTime.now().millisecondsSinceEpoch}_$i';
          final ref = _storage.ref().child(
            'documents/${currentUser.id}/$docId.jpg',
          );
          final metadata = SettableMetadata(contentType: 'image/jpeg');
          final taskSnapshot = await ref.putFile(docFile, metadata);
          docUrl = await taskSnapshot.ref.getDownloadURL();
        } catch (e) {
          print('DEBUG: Document Storage failed ($e). Using Base64.');
          final bytes = await docFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          docUrl = 'data:image/jpeg;base64,$base64Image';
        }
        finalDocumentUrls.add(docUrl);
      }

      // Update Firestore
      await _db.collection('users').doc(currentUser.id).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'bio': bioController.text.trim(),
        'address': addressController.text.trim(),
        'skills': skills.toList(),
        'documents': finalDocumentUrls,
        'avatarUrl': avatarUrl,
      });

      // Update Local State
      currentUser.name = nameController.text.trim();
      currentUser.phone = phoneController.text.trim();
      currentUser.bio = bioController.text.trim();
      currentUser.address = addressController.text.trim();
      currentUser.skills = skills.toList();
      currentUser.documents = finalDocumentUrls;
      currentUser.avatarUrl = avatarUrl;

      // Clear new documents list
      newDocuments.clear();
      documentUrls.value = finalDocumentUrls;
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
