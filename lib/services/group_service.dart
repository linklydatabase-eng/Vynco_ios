import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/group_model.dart';
import '../models/connection_model.dart';
import '../models/group_message_model.dart';

class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _groupsCollection = 'groups';
  static const String _connectionsCollection = 'connections';
  static const String _groupMessagesCollection = 'group_messages';

  // Default groups functionality removed - method kept for API compatibility
  static Future<void> ensureDefaultGroups(String userId) async {
    // Default groups are no longer created automatically
    return;
  }

  // Create a new group
  static Future<String> createGroup({
    required String name,
    required String description,
    required String createdBy,
    String? imageUrl,
    bool isPublic = false,
  }) async {
    try {
      // Generate invite code
      final inviteCode = _generateInviteCode();
      final qrCode = 'vynco://group/$inviteCode';
      
      final groupData = {
        'name': name,
        'description': description,
        'createdBy': createdBy,
        'imageUrl': imageUrl,
        'members': [createdBy],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'qrCode': qrCode,
        'isPublic': isPublic,
        'inviteCode': inviteCode,
      };

      final docRef = await _firestore
          .collection(_groupsCollection)
          .add(groupData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Generate random invite code
  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Get all groups for a user (one-sided: only groups created by the user)
  static Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection(_groupsCollection)
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final groups = snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
      // Sort client-side to avoid composite index requirement
      groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return groups;
    });
  }

  // Add connection to group
  static Future<void> addConnectionToGroup({
    required String groupId,
    required String connectionId,
    required String connectionUserId,
  }) async {
    try {
      // Check if group exists
      final groupDoc = await _firestore.collection(_groupsCollection).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      // Add user to group members
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'members': FieldValue.arrayUnion([connectionUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update connection with group info (only if connection document exists)
      final connectionDoc = await _firestore.collection(_connectionsCollection).doc(connectionId).get();
      if (connectionDoc.exists) {
        await _firestore.collection(_connectionsCollection).doc(connectionId).update({
          'groupId': groupId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // If connection document doesn't exist, create it
        await _firestore.collection(_connectionsCollection).doc(connectionId).set({
          'userId': connectionUserId,
          'groupId': groupId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add connection to group: $e');
    }
  }

  // Remove connection from group
  static Future<void> removeConnectionFromGroup({
    required String groupId,
    required String connectionId,
    required String connectionUserId,
  }) async {
    try {
      // Remove user from group members
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'members': FieldValue.arrayRemove([connectionUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove group info from connection
      await _firestore.collection(_connectionsCollection).doc(connectionId).update({
        'groupId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove connection from group: $e');
    }
  }

  // Get group details
  static Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection(_groupsCollection).doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get group: $e');
    }
  }

  // Update group
  static Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? imageUrl,
    String? color,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (color != null) updateData['color'] = color;

      await _firestore.collection(_groupsCollection).doc(groupId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  // Delete group
  static Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection(_groupsCollection).doc(groupId).delete();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // Join group by invite code
  static Future<void> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    try {
      // Find group by invite code
      final groups = await _firestore
          .collection(_groupsCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .get();

      if (groups.docs.isEmpty) {
        throw Exception('Group not found with this invite code');
      }

      final groupDoc = groups.docs.first;
      final groupId = groupDoc.id;
      final groupData = groupDoc.data();
      final members = List<String>.from(groupData['members'] ?? []);

      // Check if user is already a member
      if (members.contains(userId)) {
        throw Exception('You are already a member of this group');
      }

      // Add user to group
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send welcome message
      await sendGroupMessage(
        groupId: groupId,
        senderId: 'system',
        senderName: 'System',
        text: '$userName joined the group',
        messageType: 'system',
      );
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  // Send group message
  static Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
    String messageType = 'text',
    String? senderProfileImageUrl,
    String? replyToMessageId,
    String? replyToText,
  }) async {
    try {
      final message = GroupMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderProfileImageUrl: senderProfileImageUrl,
        text: text,
        messageType: messageType,
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
      );

      await _firestore
          .collection(_groupMessagesCollection)
          .doc(message.id)
          .set(message.toMap());

      // Update group's last message info
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': senderName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send group message: $e');
    }
  }

  // Get group messages (simplified to avoid index requirements)
  static Stream<List<GroupMessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection(_groupMessagesCollection)
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) => GroupMessageModel.fromFirestore(doc)).toList();
      // Sort client-side to avoid composite index requirement
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  // Mark group message as read
  static Future<void> markGroupMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection(_groupMessagesCollection)
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Leave group
  static Future<void> leaveGroup({
    required String groupId,
    required String userId,
    required String userName,
  }) async {
    try {
      // Remove user from group
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send leave message
      await sendGroupMessage(
        groupId: groupId,
        senderId: 'system',
        senderName: 'System',
        text: '$userName left the group',
        messageType: 'system',
      );
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  // Get group by invite code
  static Future<GroupModel?> getGroupByInviteCode(String inviteCode) async {
    try {
      final groups = await _firestore
          .collection(_groupsCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .get();

      if (groups.docs.isEmpty) {
        return null;
      }

      return GroupModel.fromFirestore(groups.docs.first);
    } catch (e) {
      throw Exception('Failed to get group: $e');
    }
  }
}
