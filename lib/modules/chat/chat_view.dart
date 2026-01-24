import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_controller.dart';
import '../../models/chat_message_model.dart';

class ChatView extends GetView<ChatController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(controller.requestTitle)),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(child: Text('Nenhuma mensagem ainda.'));
              }
              return ListView.builder(
                reverse: true,
                itemCount: controller.messages.length,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMe =
                      message.senderId ==
                      FirebaseAuth.instance.currentUser?.uid;
                  return _buildMessageBubble(message, isMe);
                },
              );
            }),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFFDE3344) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
          ),
        ),
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            if (isMe) ...[
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    message.status == 'read' ? Icons.done_all : Icons.check,
                    size: 16,
                    color: message.status == 'read'
                        ? Colors.white
                        : Colors.white70,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.messageController,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => controller.sendMessage(),
              ),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: controller.sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
