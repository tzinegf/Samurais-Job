import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import '../../models/catalog_service_model.dart';
import '../../utils/samurai_ranking_helper.dart';
import '../../utils/phone_input_formatter.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  ImageProvider? _getBackgroundImage(File? selectedFile, String? avatarUrl) {
    if (selectedFile != null) {
      return FileImage(selectedFile);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final base64String = avatarUrl.split(',').last;
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          print('Erro ao decodificar imagem Base64: $e');
          return null;
        }
      }
      return NetworkImage(avatarUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Perfil'),
        backgroundColor: Color(0xFFDE3344),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final user = controller.user.value;
        if (user == null) return Center(child: CircularProgressIndicator());

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFFDE3344), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _getBackgroundImage(
                          controller.selectedImage.value,
                          user.avatarUrl,
                        ),
                        child:
                            (controller.selectedImage.value == null &&
                                user.avatarUrl == null)
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(fontSize: 40),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: controller.pickImage,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFDE3344),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Dados Pessoais Section
              Text(
                'Dados Pessoais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextField(
                controller: TextEditingController(text: user.email),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: controller.cpfController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CPF',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: controller.rgController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'RG',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.perm_identity),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 24),

              // Endereço Section
              Text(
                'Endereço',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextField(
                controller: controller.cepController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CEP',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_post_office),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: controller.addressController,
                decoration: InputDecoration(
                  labelText: 'Endereço',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: controller.addressNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Número',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home_filled),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: controller.addressStateController,
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Professional Specific Fields
              _buildProfessionalStats(user),
              SizedBox(height: 24),

              TextField(
                controller: controller.bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Biografia Profissional',
                  hintText: 'Conte um pouco sobre sua experiência...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              SizedBox(height: 24),

              Text(
                'Habilidades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // Add Skill Button (Catalog)
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.skills.length >= 5
                      ? null
                      : () => _showAddSkillDialog(context),
                  icon: Icon(Icons.add),
                  label: Text(
                    controller.skills.length >= 5
                        ? 'Limite de 5 habilidades atingido'
                        : 'Adicionar Habilidade do Catálogo',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFDE3344),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Manual Entry (Optional, keeping for flexibility or removing if desired.
              // User asked to search in categories, so catalog is primary.
              // I'll keep manual as a secondary "Other" option if needed, but for now let's focus on the catalog button as requested)
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.skills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () => controller.removeSkill(skill),
                      backgroundColor: Color(0xFFDE3344).withOpacity(0.1),
                      side: BorderSide(
                        color: Color(0xFFDE3344).withOpacity(0.3),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 24),

              SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Color(0xFFDE3344),
                  foregroundColor: Colors.white,
                ),
                child: controller.isLoading.value
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Salvar Alterações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfessionalStats(dynamic user) {
    double progress = SamuraiRankHelper.getProgress(user);
    String currentRank = SamuraiRankHelper.getRankLabel(user.ranking);
    String nextRank = SamuraiRankHelper.getRankLabel(
      SamuraiRankHelper.getNextRank(user.ranking),
    );

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Samurai',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text(
                  '${user.rating.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  ' (${user.ratingCount} avaliações)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.work, color: Color(0xFFDE3344), size: 20),
                SizedBox(width: 8),
                Text(
                  '${user.completedServicesCount} serviços executados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nível: $currentRank',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Próximo: $nextRank',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDE3344)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context) {
    // Reset selection state when opening dialog
    controller.selectedCategory.value = null;
    controller.selectedSubcategory.value = null;
    controller.selectedService.value = null;
    controller.subcategories.clear();
    controller.services.clear();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Adicionar Habilidade',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // CATEGORY
              Obx(() {
                if (controller.isLoadingCatalog.value &&
                    controller.categories.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }
                return DropdownButtonFormField<CategoryModel>(
                  value: controller.selectedCategory.value,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.categories.map((CategoryModel cat) {
                    return DropdownMenuItem<CategoryModel>(
                      value: cat,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: controller.onCategorySelected,
                );
              }),
              SizedBox(height: 16),

              // SUBCATEGORY
              Obx(() {
                if (controller.selectedCategory.value == null)
                  return SizedBox.shrink();

                if (controller.isLoadingCatalog.value &&
                    controller.subcategories.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    DropdownButtonFormField<SubcategoryModel>(
                      value: controller.selectedSubcategory.value,
                      decoration: InputDecoration(
                        labelText: 'Subcategoria',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.subcategories.map((
                        SubcategoryModel sub,
                      ) {
                        return DropdownMenuItem<SubcategoryModel>(
                          value: sub,
                          child: Text(sub.name),
                        );
                      }).toList(),
                      onChanged: controller.onSubcategorySelected,
                    ),
                    SizedBox(height: 16),
                  ],
                );
              }),

              // SERVICE
              Obx(() {
                if (controller.selectedSubcategory.value == null)
                  return SizedBox.shrink();

                if (controller.isLoadingCatalog.value &&
                    controller.services.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                if (controller.services.isEmpty) {
                  return SizedBox.shrink(); // No specific services available
                }

                return Column(
                  children: [
                    DropdownButtonFormField<CatalogServiceModel>(
                      value: controller.selectedService.value,
                      decoration: InputDecoration(
                        labelText: 'Serviço Específico (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.services.map((CatalogServiceModel srv) {
                        return DropdownMenuItem<CatalogServiceModel>(
                          value: srv,
                          child: Text(srv.name),
                        );
                      }).toList(),
                      onChanged: controller.onServiceSelected,
                    ),
                    SizedBox(height: 16),
                  ],
                );
              }),

              // ADD BUTTON
              ElevatedButton(
                onPressed: () {
                  String? skillToAdd;
                  if (controller.selectedService.value != null) {
                    skillToAdd = controller.selectedService.value!.name;
                  } else if (controller.selectedSubcategory.value != null) {
                    skillToAdd = controller.selectedSubcategory.value!.name;
                  } else if (controller.selectedCategory.value != null) {
                    skillToAdd = controller.selectedCategory.value!.name;
                  }

                  if (skillToAdd != null) {
                    controller.addCatalogSkill(skillToAdd);
                  } else {
                    Get.snackbar(
                      'Erro',
                      'Selecione pelo menos uma categoria.',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDE3344),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Adicionar Habilidade'),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
