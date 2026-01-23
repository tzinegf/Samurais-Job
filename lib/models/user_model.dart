import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? id;
  String name;
  String email;
  String role;
  String? phone;
  String? bio;
  String? avatarUrl;
  List<String>? skills;
  int coins;
  double rating;
  int ratingCount;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.bio,
    this.avatarUrl,
    this.skills,
    this.coins = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
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
      avatarUrl: data['avatarUrl'],
      skills: data['skills'] != null ? List<String>.from(data['skills']) : [],
      coins: data['coins'] ?? 0,
      rating: (data['rating'] is int)
          ? (data['rating'] as int).toDouble()
          : (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'skills': skills,
      'coins': coins,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
