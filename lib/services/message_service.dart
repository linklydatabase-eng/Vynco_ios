import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class MessageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _messagesCollection = 'messages';
  static const String _chatsCollection = 'chats';

  // Send a message
  static Future<void> sendMessage(MessageModel message) async {
    try {
      final chatId = _getChatId(message.senderId, message.receiverId);
      print('📤 MessageService: Sending message with chatId: $chatId');
      
      // EXTREME SOLUTION: If sending to self, completely disable FCM
      if (message.senderId == message.receiverId) {
        print('🚫 EXTREME: Self-message detected, completely disabling FCM');
        final notificationService = NotificationService();
        
        // Completely remove FCM token from Firestore
        await notificationService.disableNotificationsForUser(message.senderId);
        
        // Wait longer to ensure server-side components pick up the change
        await Future.delayed(const Duration(seconds: 1));
        
        // Send the message
        final messageData = message.toMap();
        messageData['chatId'] = chatId;
        
        await _firestore
            .collection(_messagesCollection)
            .doc(message.id)
            .set(messageData);
        
        print('✅ MessageService: Self-message saved to Firebase');

        // Update chat document with last message info
        await _firestore
            .collection(_chatsCollection)
            .doc(chatId)
            .set({
          'lastMessage': message.text,
          'lastMessageTime': Timestamp.fromDate(message.timestamp),
          'lastMessageSender': message.senderId,
          'participants': [message.senderId, message.receiverId],
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));

        // Mark message as read for sender
        await _markMessageAsRead(message.id, message.senderId);

        // Wait another second before re-enabling
        await Future.delayed(const Duration(seconds: 2));
        
        // Re-enable notifications
        await notificationService.enableNotificationsForUser(message.senderId);
        print('✅ EXTREME: Re-enabled notifications after self-message');
        
        return; // Exit early for self-messages
      }
      
      // Normal message flow for non-self messages
      final messageData = message.toMap();
      messageData['chatId'] = chatId;
      
      await _firestore
          .collection(_messagesCollection)
          .doc(message.id)
          .set(messageData);
      
      print('✅ MessageService: Message saved to Firebase');

      // Update chat document with last message info
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .set({
        'lastMessage': message.text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageSender': message.senderId,
        'participants': [message.senderId, message.receiverId],
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      // Mark message as read for sender
      await _markMessageAsRead(message.id, message.senderId);

      // Send push notification to receiver
      await _sendMessageNotification(message);
      
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Send push notification for new message
  static Future<void> _sendMessageNotification(MessageModel message) async {
    try {
      // CRITICAL: Don't send notification if sender and receiver are the same
      if (message.senderId == message.receiverId) {
        print('🚫 MessageService: Skipping self-notification for sender: ${message.senderId}');
        return;
      }
      
      // Do not block notifications just because current device is the sender.
      // Only skip for true self-messages handled above.

      // Get sender's information
      final senderDoc = await _firestore.collection('users').doc(message.senderId).get();
      if (!senderDoc.exists) {
        print('❌ Sender not found: ${message.senderId}');
        return;
      }

      final senderData = senderDoc.data()!;
      final senderName = senderData['fullName'] ?? senderData['username'] ?? 'Someone';
      final senderProfileImageUrl = senderData['profileImageUrl'];

      // Write notification document directly (ensures it appears in receiver feed)
      await _firestore.collection('notifications').add({
        'receiverId': message.receiverId,
        'title': 'New message from $senderName',
        'body': message.text.length > 50 ? '${message.text.substring(0, 50)}...' : message.text,
        'data': {
          'type': 'message',
          'senderId': message.senderId,
          'senderName': senderName,
          'receiverId': message.receiverId,
          'messageText': message.text,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
        'type': 'message',
      });

      // Fire best-effort push via NotificationService
      final notificationService = NotificationService();
      await notificationService.sendMessageNotification(
        senderId: message.senderId,
        senderName: senderName,
        receiverId: message.receiverId,
        messageText: message.text,
        senderProfileImageUrl: senderProfileImageUrl,
      );

      print('📤 MessageService: Notification sent for message from $senderName');
    } catch (e) {
      print('❌ MessageService: Failed to send notification: $e');
      // Don't throw error here as message was already sent successfully
    }
  }

  // Get messages for a chat with pagination support
  static Stream<List<MessageModel>> getMessages(String senderId, String receiverId, {int limit = 50}) {
    final chatId = _getChatId(senderId, receiverId);
    print('📱 MessageService: Getting messages for chatId: $chatId (limit: $limit)');
    
    return _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      print('📱 MessageService: Found ${snapshot.docs.length} messages');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel.fromMap(data);
      }).toList();
    });
  }
  
  // Get older messages with pagination (for loading more)
  static Future<List<MessageModel>> getOlderMessages(String senderId, String receiverId, DateTime beforeTimestamp, {int limit = 50}) async {
    final chatId = _getChatId(senderId, receiverId);
    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('timestamp', isLessThan: Timestamp.fromDate(beforeTimestamp))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error loading older messages: $e');
      return [];
    }
  }

  // Mark message as read
  static Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Mark all messages in a chat as read
  static Future<void> markChatAsRead(String senderId, String receiverId) async {
    try {
      final chatId = _getChatId(senderId, receiverId);
      final batch = _firestore.batch();
      
      final messages = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: receiverId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in messages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark chat as read: $e');
    }
  }

  // Delete a message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'deletedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Edit a message
  static Future<void> editMessage(String messageId, String newText) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // Add reaction to message
  static Future<void> addReaction(String messageId, String reaction) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'reactions': FieldValue.arrayUnion([reaction]),
      });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  // Remove reaction from message
  static Future<void> removeReaction(String messageId, String reaction) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'reactions': FieldValue.arrayRemove([reaction]),
      });
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // Get chat list for a user
  static Stream<List<Map<String, dynamic>>> getChats(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'chatId': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Get unread message count for a user
  static Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // Set typing status
  static Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .update({
        'typing': {
          userId: isTyping,
        },
        'typingUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to set typing status: $e');
    }
  }

  // Get typing status
  static Stream<Map<String, bool>> getTypingStatus(String chatId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data != null && data['typing'] != null) {
        return Map<String, bool>.from(data['typing']);
      }
      return {};
    });
  }

  // Helper method to generate consistent chat ID
  static String _getChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Helper method to mark message as read
  static Future<void> _markMessageAsRead(String messageId, String userId) async {
    await _firestore
        .collection(_messagesCollection)
        .doc(messageId)
        .update({
      'isRead': true,
      'readAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
