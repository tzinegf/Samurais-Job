import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? id;
  String name;
  String email;
  String role;
  String? phone;
  String? bio;
  List<String>? skills;
  int coins;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.bio,
    this.skills,
    this.coins = 0,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'client',
      phone: data['phone'],
      bio: data['bio'],
      skills: data['skills'] != null ? List<String>.from(data['skills']) : [],
      coins: data['coins'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'bio': bio,
      'skills': skills,
      'coins': coins,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
