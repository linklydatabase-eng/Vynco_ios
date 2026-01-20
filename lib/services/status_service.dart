import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      try {
        if (connectionsSnapshot.docs.isEmpty) {
          // No connections, return empty list
          return <StatusModel>[];
        }
        
        // Get connection user IDs
        List<String> connectionUserIds = connectionsSnapshot.docs
            .map((doc) {
              final data = doc.data();
              final dynamic raw = data['contactUserId'];
              return raw is String && raw.isNotEmpty ? raw : null;
            })
            .whereType<String>()
            .toList();
        
        if (connectionUserIds.isEmpty) {
          return <StatusModel>[];
        }
        
        // Firestore whereIn has a limit of 10 items, so batch the queries
        List<StatusModel> allStatuses = [];
        const int batchSize = 10;
        
        for (int i = 0; i < connectionUserIds.length; i += batchSize) {
          final batch = connectionUserIds.skip(i).take(batchSize).toList();
          
          final statusesSnapshot = await _firestore
              .collection('statuses')
              .where('userId', whereIn: batch)
              .orderBy('createdAt', descending: true)
              .get();
          
          final batchStatuses = <StatusModel>[];
          
          for (final doc in statusesSnapshot.docs) {
            StatusModel status = StatusModel.fromMap(doc.data());
            
            debugPrint('📱 Status: ${status.userName}, userProfileImageUrl: ${status.userProfileImageUrl}');
            
            // If userProfileImageUrl is missing, try to fetch it from the user document
            if (status.userProfileImageUrl == null || status.userProfileImageUrl!.isEmpty) {
              try {
                final userDoc = await _firestore
                    .collection('users')
                    .doc(status.userId)
                    .get();
                
                if (userDoc.exists) {
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final profileImageUrl = userData['profileImageUrl'] as String?;
                  
                  debugPrint('👤 Fetched user ${status.userId}: profileImageUrl = $profileImageUrl');
                  
                  if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
                    status = status.copyWith(userProfileImageUrl: profileImageUrl);
                  }
                } else {
                  debugPrint('⚠️ User document not found for ${status.userId}');
                }
              } catch (e) {
                debugPrint('❌ Error fetching user profile: $e');
              }
            }

            // Fallback: if this status belongs to the current user and Firestore has no photo,
            // try the Firebase Auth photoURL so their uploaded avatar still shows.
            if ((status.userProfileImageUrl == null || status.userProfileImageUrl!.isEmpty) &&
                status.userId == currentUserId) {
              final authPhoto = FirebaseAuth.instance.currentUser?.photoURL;
              if (authPhoto != null && authPhoto.isNotEmpty) {
                status = status.copyWith(userProfileImageUrl: authPhoto);
              }
            }
            
            batchStatuses.add(status);
          }
          
          allStatuses.addAll(batchStatuses.where((status) => !status.isExpired));
        }
        
        // Sort all statuses by creation time after combining batches
        allStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return allStatuses;
      } catch (e) {
        // Return empty list on error instead of throwing
        debugPrint('Error loading statuses: $e');
        return <StatusModel>[];
      }
    });
  }

  // Get current user's statuses
  Stream<List<StatusModel>> getUserStatuses(String userId) {
    return _firestore
        .collection('statuses')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final statuses = <StatusModel>[];
      
      for (final doc in snapshot.docs) {
        StatusModel status = StatusModel.fromMap(doc.data());
        
        // If userProfileImageUrl is missing, try to fetch it from the user document
        if (status.userProfileImageUrl == null || status.userProfileImageUrl!.isEmpty) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(status.userId)
                .get();
            
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final profileImageUrl = userData['profileImageUrl'] as String?;
              
              if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
                status = status.copyWith(userProfileImageUrl: profileImageUrl);
              }
            }
          } catch (e) {
            debugPrint('Error fetching user profile: $e');
          }
        }

        // Fallback: for own statuses, try Firebase Auth photoURL if Firestore is missing it.
        if ((status.userProfileImageUrl == null || status.userProfileImageUrl!.isEmpty) &&
            status.userId == userId) {
          final authPhoto = FirebaseAuth.instance.currentUser?.photoURL;
          if (authPhoto != null && authPhoto.isNotEmpty) {
            status = status.copyWith(userProfileImageUrl: authPhoto);
          }
        }
        
        statuses.add(status);
      }
      
      return statuses.where((status) => !status.isExpired).toList();
    });
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
