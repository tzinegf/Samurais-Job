import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteModel {
  String? id;
  String requestId;
  String professionalId;
  String professionalName;
  double price;
  String description;
  bool isExclusive;
  String status; // pending, accepted, rejected
  String? professionalRank;
  double? professionalRating;
  int? professionalCompletedServices;
  DateTime? createdAt;
  String? deadline; // Prazo de execução (ex: "2 dias", "1 semana")

  QuoteModel({
    this.id,
    required this.requestId,
    required this.professionalId,
    required this.professionalName,
    required this.price,
    required this.description,
    this.isExclusive = false,
    this.status = 'pending',
    this.professionalRank,
    this.professionalRating,
    this.professionalCompletedServices,
    this.createdAt,
    this.deadline,
  });

  factory QuoteModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuoteModel(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      professionalId: data['professionalId'] ?? '',
      professionalName: data['professionalName'] ?? 'Profissional',
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] as double?) ?? 0.0,
      description: data['description'] ?? '',
      isExclusive: data['isExclusive'] ?? false,
      status: data['status'] ?? 'pending',
      professionalRank: data['professionalRank'],
      professionalRating: (data['professionalRating'] is int)
          ? (data['professionalRating'] as int).toDouble()
          : (data['professionalRating'] as double?),
      professionalCompletedServices: data['professionalCompletedServices'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      deadline: data['deadline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'price': price,
      'description': description,
      'isExclusive': isExclusive,
      'status': status,
      'professionalRank': professionalRank,
      'professionalRating': professionalRating,
      'professionalCompletedServices': professionalCompletedServices,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'deadline': deadline,
    };
  }
}
