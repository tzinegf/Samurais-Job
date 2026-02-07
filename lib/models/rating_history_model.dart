import 'package:cloud_firestore/cloud_firestore.dart';

class RatingHistoryModel {
  String? id;
  String professionalId;
  String clientId;
  String requestId;
  double oldRating;
  double newRating;
  double givenRating; // The rating given by the client (raw)
  double processedRating; // The rating after extreme value processing
  String professionalRank;
  DateTime timestamp;
  String trigger; // 'service_completion'

  RatingHistoryModel({
    this.id,
    required this.professionalId,
    required this.clientId,
    required this.requestId,
    required this.oldRating,
    required this.newRating,
    required this.givenRating,
    required this.processedRating,
    required this.professionalRank,
    required this.timestamp,
    this.trigger = 'service_completion',
  });

  Map<String, dynamic> toJson() {
    return {
      'professionalId': professionalId,
      'clientId': clientId,
      'requestId': requestId,
      'oldRating': oldRating,
      'newRating': newRating,
      'givenRating': givenRating,
      'processedRating': processedRating,
      'professionalRank': professionalRank,
      'timestamp': Timestamp.fromDate(timestamp),
      'trigger': trigger,
    };
  }
}
