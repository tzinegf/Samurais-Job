import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_message_model.dart';

class ChatController extends GetxController {
  final String requestId = Get.arguments['requestId'];
  late RxString requestTitle = (Get.arguments['requestTitle'] as String? ?? 'Chat').obs;
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? receiverId;
  RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments['requestTitle'] == null) {
      _fetchRequestTitle();
    }
    _identifyReceiver();
    _setChatActive(true);
    _listenToMessages();
  }

  Future<void> _fetchRequestTitle() async {
    try {
      final doc = await _firestore.collection('service_requests').doc(requestId).get();
      if (doc.exists) {
        requestTitle.value = doc.data()?['title'] ?? 'Chat';
      }
    } catch (e) {
      print('Erro ao buscar título do pedido: $e');
    }
  }

  @override
  void onClose() {
    _setChatActive(false);
    super.onClose();
  }

  Future<void> _setChatActive(bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    if (isActive) {
      await prefs.setString('current_chat_id', requestId);
    } else {
      // Only clear if it matches (in case we navigated to another chat quickly)
      if (prefs.getString('current_chat_id') == requestId) {
        await prefs.remove('current_chat_id');
      }
    }
  }

  Future<void> _identifyReceiver() async {
    final user = _auth.currentUser;
    if (user == null) return;

    print('DEBUG: Identificando receiver para request $requestId...');

    try {
      final doc = await _firestore
          .collection('service_requests')
          .doc(requestId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final clientId = data['clientId'];
        final professionalId = data['professionalId'];

        print(
          'DEBUG: Client: $clientId, Professional: $professionalId, Me: ${user.uid}',
        );

        if (user.uid == clientId) {
          // I am the client
          // If there is an assigned professional, they are the receiver.
          // If not (public Q&A), we might leave receiverId null or handle differently.
          receiverId = professionalId;
        } else {
          // I am NOT the client (I am a professional/bidder)
          // The receiver is ALWAYS the client
          receiverId = clientId;
        }

        if (receiverId == null) {
          print(
            'DEBUG: AVISO - ReceiverId é null. (Sou cliente e não há profissional atribuído?)',
          );
        } else {
          print('DEBUG: Receiver identificado: $receiverId');
        }
      } else {
        print('DEBUG: Request doc não encontrado.');
      }
    } catch (e) {
      print('Erro ao identificar receiver: $e');
    }
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

    // Force identify if null
    if (receiverId == null) {
      print(
        'DEBUG: receiverId é null ao enviar. Tentando identificar novamente...',
      );
      await _identifyReceiver();
    }

    final message = messageController.text.trim();
    messageController.clear();

    // Tenta obter o nome do usuário do Firebase Auth
    String senderName = user.displayName ?? user.email ?? 'Usuário';

    print('DEBUG: Enviando mensagem para receiverId: $receiverId');

    if (receiverId == null) {
      Get.snackbar(
        'Aviso',
        'Destinatário não identificado. A notificação pode não ser enviada.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }

    final chatMessage = ChatMessageModel(
      id: '', // Firestore gera
      senderId: user.uid,
      message: message,
      timestamp: DateTime.now(),
      senderName: senderName,
      status: 'sent',
      receiverId: receiverId,
    );

    await _firestore
        .collection('service_requests')
        .doc(requestId)
        .collection('messages')
        .add(chatMessage.toMap());
  }
}
