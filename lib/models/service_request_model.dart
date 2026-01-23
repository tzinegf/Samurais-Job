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
  DateTime? completedAt;
  double? rating;
  String? review;
  bool? hasProblem;
  String? problemDescription;

  // Professional's rating of the client
  double? clientRating;
  String? clientReview;
  bool? professionalHasProblem;
  String? professionalProblemDescription;

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
    this.completedAt,
    this.rating,
    this.review,
    this.hasProblem,
    this.problemDescription,
    this.clientRating,
    this.clientReview,
    this.professionalHasProblem,
    this.professionalProblemDescription,
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
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      rating: (data['rating'] is int)
          ? (data['rating'] as int).toDouble()
          : (data['rating'] as double?),
      review: data['review'],
      hasProblem: data['hasProblem'],
      problemDescription: data['problemDescription'],
      clientRating: (data['clientRating'] is int)
          ? (data['clientRating'] as int).toDouble()
          : (data['clientRating'] as double?),
      clientReview: data['clientReview'],
      professionalHasProblem: data['professionalHasProblem'],
      professionalProblemDescription: data['professionalProblemDescription'],
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
      'completedAt': completedAt,
      'rating': rating,
      'review': review,
      'hasProblem': hasProblem,
      'problemDescription': problemDescription,
      'clientRating': clientRating,
      'clientReview': clientReview,
      'professionalHasProblem': professionalHasProblem,
      'professionalProblemDescription': professionalProblemDescription,
    };
  }
}
