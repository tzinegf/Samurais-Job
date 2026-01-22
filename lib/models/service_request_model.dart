import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequestModel {
  String? id;
  String clientId;
  String? professionalId;
  String title;
  String description;
  String category;
  String status; // pending, accepted, completed, cancelled
  double? price;
  DateTime? createdAt;

  ServiceRequestModel({
    this.id,
    required this.clientId,
    this.professionalId,
    required this.title,
    required this.description,
    required this.category,
    this.status = 'pending',
    this.price,
    this.createdAt,
  });

  factory ServiceRequestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequestModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      professionalId: data['professionalId'],
      title: data['title'] ?? 'Sem Título',
      description: data['description'] ?? 'Sem Descrição',
      category: data['category'] ?? 'Outros',
      status: data['status'] ?? 'pending',
      price: (data['price'] is int) 
          ? (data['price'] as int).toDouble() 
          : (data['price'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'professionalId': professionalId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'price': price,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
