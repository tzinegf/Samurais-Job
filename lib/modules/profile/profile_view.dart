import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/samurai_ranking_helper.dart';
import 'profile_controller.dart';

import '../../utils/phone_input_formatter.dart';

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

              // Basic Info
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
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
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

              // Professional Specific Fields
              if (user.role == 'professional') ...[
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.skillController,
                        decoration: InputDecoration(
                          hintText: 'Adicionar habilidade (ex: Encanador)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onSubmitted: (_) => controller.addSkill(),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: controller.addSkill,
                      icon: Icon(
                        Icons.add_circle,
                        color: Color(0xFFDE3344),
                        size: 32,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
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
                _buildDocumentsSection(controller),
              ],

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

  Widget _buildDocumentsSection(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Obx(() {
          final docs = controller.documentUrls;
          final newDocs = controller.newDocuments;

          if (docs.isEmpty && newDocs.isEmpty) {
            return Text(
              'Nenhum documento enviado.',
              style: TextStyle(color: Colors.grey),
            );
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...docs.map(
                (url) => _buildDocThumb(
                  url,
                  isUrl: true,
                  onDelete: () => controller.removeExistingDocument(url),
                ),
              ),
              ...newDocs.asMap().entries.map(
                (entry) => _buildDocThumb(
                  entry.value.path,
                  isUrl: false,
                  onDelete: () => controller.removeNewDocument(entry.key),
                ),
              ),
            ],
          );
        }),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: controller.pickDocument,
          icon: Icon(Icons.upload_file),
          label: Text('Adicionar Documento'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFFDE3344),
            side: BorderSide(color: Color(0xFFDE3344)),
          ),
        ),
      ],
    );
  }

  Widget _buildDocThumb(
    String path, {
    required bool isUrl,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: isUrl
                  ? (path.startsWith('data:image')
                            ? MemoryImage(base64Decode(path.split(',').last))
                            : NetworkImage(path))
                        as ImageProvider
                  : FileImage(File(path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
