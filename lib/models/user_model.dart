import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? id;
  String name;
  String email;
  String role;
  String? phone;
  String? cpf;
  String? rg;
  String? bio;
  String? address;
  String? cep;
  String? addressNumber;
  String? addressState;
  List<String>? documents;
  String? avatarUrl;
  List<String>? skills;
  int coins;
  double rating;
  int ratingCount;
  int completedServicesCount;
  int cancellationCount;
  String ranking; // ronin, ashigaru, bushi, hatamoto, daimyo, shogun

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.cpf,
    this.rg,
    this.bio,
    this.address,
    this.cep,
    this.addressNumber,
    this.addressState,
    this.documents,
    this.avatarUrl,
    this.skills,
    this.coins = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.completedServicesCount = 0,
    this.cancellationCount = 0,
    this.ranking = 'ronin',
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'client',
      phone: data['phone'],
      cpf: data['cpf'],
      rg: data['rg'],
      bio: data['bio'],
      address: data['address'],
      cep: data['cep'],
      addressNumber: data['addressNumber'],
      addressState: data['addressState'],
      documents: data['documents'] != null
          ? List<String>.from(data['documents'])
          : [],
      avatarUrl: data['avatarUrl'],
      skills: data['skills'] != null ? List<String>.from(data['skills']) : [],
      coins: data['coins'] ?? 0,
      rating: (data['rating'] is int)
          ? (data['rating'] as int).toDouble()
          : (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      completedServicesCount: data['completedServicesCount'] ?? 0,
      cancellationCount: data['cancellationCount'] ?? 0,
      ranking: data['ranking'] ?? 'ronin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'cpf': cpf,
      'rg': rg,
      'bio': bio,
      'address': address,
      'cep': cep,
      'addressNumber': addressNumber,
      'addressState': addressState,
      'documents': documents,
      'avatarUrl': avatarUrl,
      'skills': skills,
      'coins': coins,
      'rating': rating,
      'ratingCount': ratingCount,
      'completedServicesCount': completedServicesCount,
      'cancellationCount': cancellationCount,
      'ranking': ranking,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
