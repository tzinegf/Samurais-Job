import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'register_controller.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';

import '../../utils/phone_input_formatter.dart';

class RegisterView extends GetView<RegisterController> {
  final RxBool isObscure = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Criar Nova Conta'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Junte-se ao Samurais Job',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Preencha seus dados para começar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            _buildTextField(
              controller: controller.nameCtrl,
              label: 'Nome Completo',
              icon: Icons.person_outline,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: controller.emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: controller.phoneCtrl,
              label: 'Telefone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: controller.passwordCtrl,
              label: 'Senha',
              icon: Icons.lock_outline,
              isPassword: true,
            ),

            SizedBox(height: 24),
            Text(
              'Dados Profissionais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),

            Obx(() {
              if (controller.isLoadingCatalog.value) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Dropdown
                    DropdownButtonFormField<CategoryModel>(
                      value: controller.selectedCategory.value,
                      decoration: _inputDecoration(
                        'Categoria Principal',
                        Icons.category_outlined,
                      ),
                      items: controller.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: controller.onCategorySelected,
                    ),
                    SizedBox(height: 16),

                    // Subcategory Dropdown
                    DropdownButtonFormField<SubcategoryModel>(
                      value: controller.selectedSubcategory.value,
                      decoration: _inputDecoration(
                        'Subcategoria',
                        Icons.subdirectory_arrow_right,
                      ),
                      items: controller.subcategories.map((subcategory) {
                        return DropdownMenuItem(
                          value: subcategory,
                          child: Text(subcategory.name),
                        );
                      }).toList(),
                      onChanged: controller.onSubcategorySelected,
                    ),
                    SizedBox(height: 24),

                    // Services Selection
                    if (controller.services.isNotEmpty) ...[
                      Text(
                        'Selecione suas habilidades (Máx 5):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: controller.services.map((service) {
                          return Obx(() {
                            final isSelected = controller.selectedSkills
                                .contains(service.name);
                            return FilterChip(
                              label: Text(service.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                controller.toggleSkill(service.name);
                              },
                              selectedColor: Color(0xFFDE3344).withOpacity(0.1),
                              checkmarkColor: Color(0xFFDE3344),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Color(0xFFDE3344)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? Color(0xFFDE3344)
                                      : Colors.grey.shade300,
                                ),
                              ),
                            );
                          });
                        }).toList(),
                      ),
                    ] else if (controller.selectedSubcategory.value !=
                        null) ...[
                      Text(
                        'Nenhum serviço encontrado para esta subcategoria.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                );
              }
            }),

            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => controller.register(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDE3344),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: Text('CRIAR CONTA'),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    if (isPassword) {
      return Obx(
        () => TextField(
          controller: controller,
          obscureText: isObscure.value,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: _inputDecoration(label, icon).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                isObscure.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => isObscure.toggle(),
            ),
          ),
        ),
      );
    }
    return TextField(
      controller: controller,
      obscureText: false,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFDE3344), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
