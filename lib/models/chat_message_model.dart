import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final String senderName;
  final String status; // sent, read

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.senderName,
    this.status = 'sent',
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderName: data['senderName'] ?? '',
      status: data['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'senderName': senderName,
      'status': status,
    };
  }
}
