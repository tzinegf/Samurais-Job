import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? id;
  String title;
  String body;
  DateTime timestamp;
  bool isRead;
  String type; // 'quote_received', 'order_adjustment', 'order_accepted', 'order_cancelled', etc.
  String? relatedId; // ID of the related object (ServiceRequest, Quote, etc.)

  NotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.relatedId,
  });

  factory NotificationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? 'general',
      relatedId: data['relatedId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type,
      'relatedId': relatedId,
    };
  }
}
