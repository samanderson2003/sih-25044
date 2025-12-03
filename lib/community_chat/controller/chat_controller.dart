import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/chat_message.dart';

class ChatController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController messageController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of messages from Firestore
  Stream<List<ChatMessage>> get messagesStream {
    return _firestore
        .collection('community_chat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to chat.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final displayName = user.displayName ?? user.email ?? 'Anonymous';

      final message = ChatMessage(
        id: '', // Will be set by Firestore
        text: messageController.text.trim(),
        senderId: user.uid,
        senderName: displayName,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('community_chat').add(message.toMap());
      messageController.clear();
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('community_chat').doc(messageId).delete();
    } catch (e) {
      _errorMessage = 'Failed to delete message: $e';
      notifyListeners();
    }
  }

  Future<void> addReaction(String messageId, String reaction) async {
    try {
      await _firestore.collection('community_chat').doc(messageId).update({
        'reactions': FieldValue.arrayUnion([reaction]),
      });
    } catch (e) {
      _errorMessage = 'Failed to add reaction: $e';
      notifyListeners();
    }
  }

  bool isMyMessage(String senderId) {
    return senderId == currentUserId;
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
