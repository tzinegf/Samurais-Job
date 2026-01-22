import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_message_model.dart';

class ChatController extends GetxController {
  final String requestId = Get.arguments['requestId'];
  final String requestTitle = Get.arguments['requestTitle'];
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _listenToMessages();
  }

  void _listenToMessages() {
    _firestore
        .collection('service_requests')
        .doc(requestId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          messages.value = snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList();

          _markMessagesAsRead(snapshot.docs);
        });
  }

  void _markMessagesAsRead(List<QueryDocumentSnapshot> docs) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = data['senderId'];
      final status = data['status'] ?? 'sent';

      // Se a mensagem não é minha e ainda não foi lida, marca como lida
      if (senderId != currentUser.uid && status != 'read') {
        doc.reference.update({'status': 'read'});
      }
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final message = messageController.text.trim();
    messageController.clear();

    // Tenta obter o nome do usuário do Firebase Auth
    String senderName = user.displayName ?? user.email ?? 'Usuário';

    final chatMessage = ChatMessageModel(
      id: '', // Firestore gera
      senderId: user.uid,
      message: message,
      timestamp: DateTime.now(),
      senderName: senderName,
      status: 'sent',
    );

    await _firestore
        .collection('service_requests')
        .doc(requestId)
        .collection('messages')
        .add(chatMessage.toMap());
  }
}
