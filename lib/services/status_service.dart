import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/status_model.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Use the default bucket from Firebase initialization
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new status
  Future<String> createStatus({
    required String userId,
    required String userName,
    String? userProfileImageUrl,
    String? text,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child('status_images').child(fileName);

        // Explicit metadata helps Storage route and validate content type correctly
        final metadata = SettableMetadata(contentType: 'image/jpeg');

        try {
          final uploadTask = await ref.putFile(imageFile, metadata);
          imageUrl = await uploadTask.ref.getDownloadURL();
        } on FirebaseException catch (e) {
          // Surface clear info for troubleshooting
          throw Exception(
            'Upload failed (${e.code}): ${e.message ?? 'no message'}',
          );
        }
      }

      // Create status document
      final statusId = _firestore.collection('statuses').doc().id;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24)); // Status expires in 24 hours

      final status = StatusModel(
        id: statusId,
        userId: userId,
        userName: userName,
        userProfileImageUrl: userProfileImageUrl,
        text: text,
        imageUrl: imageUrl,
        createdAt: now,
        expiresAt: expiresAt,
      );

      await _firestore.collection('statuses').doc(statusId).set(status.toMap());
      
      return statusId;
    } catch (e) {
      throw Exception('Failed to create status: $e');
    }
  }

  // Get all active statuses for a user's connections only
  Stream<List<StatusModel>> getStatuses(String currentUserId) {
    // First get the user's connections
    return _firestore
        .collection('connections')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((connectionsSnapshot) async {
      if (connectionsSnapshot.docs.isEmpty) {
        // No connections, return empty list
        return <StatusModel>[];
      }
      
      // Get connection user IDs
      List<String> connectionUserIds = connectionsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dynamic raw = data['contactUserId'];
            return raw is String && raw.isNotEmpty ? raw : null;
          })
          .whereType<String>()
          .toList();
      
      if (connectionUserIds.isEmpty) {
        return <StatusModel>[];
      }
      
      // Get statuses from connections only
      final statusesSnapshot = await _firestore
          .collection('statuses')
          .where('userId', whereIn: connectionUserIds)
          .orderBy('createdAt', descending: true)
          .get();
      
      return statusesSnapshot.docs
          .map((doc) => StatusModel.fromMap(doc.data()))
          .where((status) => !status.isExpired) // Filter out expired statuses
          .toList();
    });
  }

  // Get current user's statuses
  Stream<List<StatusModel>> getUserStatuses(String userId) {
    return _firestore
        .collection('statuses')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StatusModel.fromMap(doc.data()))
            .where((status) => !status.isExpired)
            .toList());
  }

  // Mark status as viewed
  Future<void> markStatusAsViewed(String statusId, String viewerId) async {
    await _firestore.collection('statuses').doc(statusId).update({
      'viewers': FieldValue.arrayUnion([viewerId]),
    });
  }

  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    try {
      // Get status to check for image
      final doc = await _firestore.collection('statuses').doc(statusId).get();
      if (doc.exists) {
        final status = StatusModel.fromMap(doc.data()!);
        
        // Delete image from storage if exists
        if (status.imageUrl != null) {
          try {
            await _storage.refFromURL(status.imageUrl!).delete();
          } catch (e) {
            // Image might already be deleted, continue
          }
        }
      }
      
      // Delete status document
      await _firestore.collection('statuses').doc(statusId).delete();
    } catch (e) {
      throw Exception('Failed to delete status: $e');
    }
  }

  // Clean up expired statuses
  Future<void> cleanupExpiredStatuses() async {
    final now = Timestamp.now();
    final expiredStatuses = await _firestore
        .collection('statuses')
        .where('expiresAt', isLessThan: now)
        .get();

    for (final doc in expiredStatuses.docs) {
      final status = StatusModel.fromMap(doc.data());
      
      // Delete image from storage if exists
      if (status.imageUrl != null) {
        try {
          await _storage.refFromURL(status.imageUrl!).delete();
        } catch (e) {
          // Image might already be deleted, continue
        }
      }
      
      // Delete status document
      await doc.reference.delete();
    }
  }
}
