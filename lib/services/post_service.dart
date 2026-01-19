import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';

class PostService extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  final String _collection = 'posts';
  bool _isFirebaseAvailable = false;
  
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;
  bool _isLoadingPosts = false; // Flag to prevent multiple simultaneous calls
  
  // Performance optimization: Cache and debounce
  Timer? _debounceTimer;
  DateTime? _lastPostsLoad;
  String? _lastUserId;
  static const _postsCacheDuration = Duration(minutes: 2);

  PostService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
      debugPrint('PostService initialized with Firebase');
    } catch (e) {
      debugPrint('PostService initialized without Firebase: $e');
      _isFirebaseAvailable = false;
      // Load mock posts immediately for demonstration
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMockPosts();
      });
    }
  }

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get posts from user and their connections only
  Future<void> getPosts({String? currentUserId, bool forceRefresh = false}) async {
    // Prevent multiple simultaneous calls
    if (_isLoadingPosts) {
      debugPrint('PostService: getPosts already in progress, skipping...');
      return;
    }
    
    // Check cache if not forcing refresh
    if (!forceRefresh && 
        currentUserId == _lastUserId &&
        _lastPostsLoad != null && 
        DateTime.now().difference(_lastPostsLoad!) < _postsCacheDuration &&
        _posts.isNotEmpty) {
      debugPrint('PostService: Using cached posts');
      return;
    }
    
    _isLoadingPosts = true;
    
    if (!_isFirebaseAvailable) {
      _loadMockPosts();
      _isLoadingPosts = false;
      return;
    }
    
    _setLoading(true);
    _error = null;
    
    debugPrint('PostService: Fetching posts for user: $currentUserId');
    
    if (currentUserId == null) {
      debugPrint('PostService: No current user, loading empty feed');
      _posts = [];
      _setLoading(false);
      _isLoadingPosts = false;
      notifyListeners();
      return;
    }

    // Retry logic for loading posts
    const maxRetries = 3;
    int retryCount = 0;
    bool success = false;

    while (retryCount < maxRetries && !success) {
      try {
        // Get user's connections with timeout
        final connectionsSnapshot = await _firestore!
            .collection('connections')
            .where('userId', isEqualTo: currentUserId)
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          throw TimeoutException('Connections query timed out');
        });

        List<String> connectionUserIds = connectionsSnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dynamic raw = data['contactUserId'];
              return raw is String && raw.isNotEmpty ? raw : null;
            })
            .whereType<String>()
            .toList();

        // Add current user to the list so they see their own posts
        connectionUserIds.add(currentUserId);

        debugPrint('PostService: Found ${connectionUserIds.length} users to fetch posts from');

        // SUPERCHARGED: Batch fetch using whereIn (chunks of 10) to reduce N+1 queries
        final List<PostModel> fetchedPosts = [];

        // Helper to chunk a list
        List<List<String>> _chunk(List<String> list, int size) {
          final List<List<String>> chunks = [];
          for (int i = 0; i < list.length; i += size) {
            chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
          }
          return chunks;
        }

        final chunks = _chunk(connectionUserIds, 10);

        // Run chunk queries in parallel with a generous limit, then distill to latest per user
        final chunkFutures = chunks.map((ids) async {
          try {
            final snap = await _firestore!
                .collection(_collection)
                .where('userId', whereIn: ids)
                .orderBy('createdAt', descending: true)
                .limit(100)
                .get()
                .timeout(const Duration(seconds: 8));
            return snap.docs.map((d) => PostModel.fromFirestore(d)).toList();
          } catch (e) {
            debugPrint('PostService: Batch whereIn failed for chunk (${ids.length}) -> $e');
            return <PostModel>[]; // continue; fallback handled later
          }
        }).toList();

        final chunkResults = await Future.wait(chunkFutures);
        for (final list in chunkResults) {
          fetchedPosts.addAll(list);
        }

        // Distill to latest post per user
        final Map<String, PostModel> latestByUser = {};
        for (final post in fetchedPosts) {
          final existing = latestByUser[post.userId];
          if (existing == null || post.createdAt.isAfter(existing.createdAt)) {
            latestByUser[post.userId] = post;
          }
        }

        // If some users are missing (e.g., no recent posts returned due to limit), fallback fetch per missing user (limit 1)
        final missingUserIds = connectionUserIds.where((id) => !latestByUser.containsKey(id)).toList();
        if (missingUserIds.isNotEmpty) {
          debugPrint('PostService: Missing latest for ${missingUserIds.length} users, fetching individually (limit 1)');
          final perUserFutures = missingUserIds.map((userId) async {
            try {
              final snap = await _firestore!
                  .collection(_collection)
                  .where('userId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .get()
                  .timeout(const Duration(seconds: 5));
              if (snap.docs.isNotEmpty) {
                return PostModel.fromFirestore(snap.docs.first);
              }
            } catch (e) {
              // As a last resort, try without orderBy
              try {
                final snap = await _firestore!
                    .collection(_collection)
                    .where('userId', isEqualTo: userId)
                    .get()
                    .timeout(const Duration(seconds: 5));
                if (snap.docs.isNotEmpty) {
                  PostModel? latest;
                  for (final doc in snap.docs) {
                    final p = PostModel.fromFirestore(doc);
                    if (latest == null || p.createdAt.isAfter(latest.createdAt)) {
                      latest = p;
                    }
                  }
                  if (latest != null) return latest;
                }
              } catch (e2) {
                debugPrint('PostService: Per-user fallback failed for $userId: $e2');
              }
            }
            return null;
          }).toList();

          final perUserResults = await Future.wait(perUserFutures);
          for (final p in perUserResults.whereType<PostModel>()) {
            final existing = latestByUser[p.userId];
            if (existing == null || p.createdAt.isAfter(existing.createdAt)) {
              latestByUser[p.userId] = p;
            }
          }
        }

        _posts = latestByUser.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint('PostService: Loaded ${_posts.length} latest posts (one per user) from user and connections');
        _lastPostsLoad = DateTime.now();
        _lastUserId = currentUserId;
        success = true;
        _error = null; // Clear any previous errors
        // Don't notify here - we'll notify at the end after setting loading to false
      } on TimeoutException {
        debugPrint('PostService: Timeout loading posts');
        _error = "We're having trouble connecting. Please verify your internet connection and try again.";
        // Fallback: try to get user's own posts only
        try {
          final userPostsSnapshot = await _firestore!
              .collection(_collection)
              .where('userId', isEqualTo: currentUserId)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get()
              .timeout(const Duration(seconds: 5));
          _posts = userPostsSnapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
          if (_posts.isNotEmpty) {
            _error = null; // Clear error if fallback succeeds
            debugPrint('PostService: Fallback loaded ${_posts.length} user posts');
          }
        } catch (fallbackError) {
          debugPrint('PostService: Fallback also failed: $fallbackError');
          _posts = [];
        }
        // Don't retry on timeout - exit loop
        break;
      } catch (e) {
        retryCount++;
        final isTransient = _isTransientError(e);

        if (isTransient && retryCount < maxRetries) {
          // Transient error - retry with exponential backoff
          final delaySeconds = retryCount;
          debugPrint('PostService: Transient error fetching posts (attempt $retryCount/$maxRetries), retrying in ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue; // Retry
        } else {
          // Non-transient error or max retries reached
          _error = e.toString();
          debugPrint('PostService: Error fetching posts: $e');
          
          // Fallback: try to get user's own posts only (only latest one)
          try {
            final userPostsSnapshot = await _firestore!
                .collection(_collection)
                .where('userId', isEqualTo: currentUserId)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .get()
                .timeout(const Duration(seconds: 5));

            _posts = userPostsSnapshot.docs
                .map((doc) => PostModel.fromFirestore(doc))
                .toList();
            
            debugPrint('PostService: Fallback loaded ${_posts.length} latest user post');
            _error = null; // Clear error if fallback succeeds
          } catch (fallbackError) {
            debugPrint('PostService: Fallback also failed: $fallbackError');
            _posts = [];
          }
          
          // Don't notify here - we'll notify at the end after setting loading to false
          break; // Exit retry loop
        }
      }
    }
    
    // Always clear loading state and notify, even on error
    _setLoading(false);
    _isLoadingPosts = false;
    notifyListeners(); // Notify once at the end with final state
  }

  void _loadMockPosts() {
    // Mock posts - only one post per user (latest post)
    _posts = [
      PostModel(
        id: '1',
        userId: 'user1',
        userName: 'Sarah Connor',
        userAvatar: 'S',
        content: 'Excited to announce my new project focusing on sustainable tech solutions! It\'s been a challenging but rewarding journey. #SustainableTech #Innovation',
        imageUrl: null,
        likes: ['user2', 'user3'],
        shares: ['user4'],
        commentsCount: 5,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      PostModel(
        id: '2',
        userId: 'user2',
        userName: 'Michael Chen',
        userAvatar: 'M',
        content: 'Reflecting on the latest trends in AI and machine learning. The pace of change is incredible, and I\'m looking forward to the next breakthroughs. #AI #MachineLearning',
        imageUrl: null,
        likes: ['user1', 'user3', 'user4'],
        shares: ['user5'],
        commentsCount: 8,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PostModel(
        id: '3',
        userId: 'user3',
        userName: 'Emily White',
        userAvatar: 'E',
        content: 'Attended an insightful webinar on remote work strategies. The future of work is definitely flexible! Sharing some key takeaways in my blog soon. #RemoteWork #FutureOfWork',
        imageUrl: null,
        likes: ['user1', 'user2'],
        shares: [],
        commentsCount: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
    // Filter to only latest post per user (for consistency with real implementation)
    Map<String, PostModel> latestPostsByUser = {};
    for (var post in _posts) {
      if (!latestPostsByUser.containsKey(post.userId) || 
          post.createdAt.isAfter(latestPostsByUser[post.userId]!.createdAt)) {
        latestPostsByUser[post.userId] = post;
      }
    }
    _posts = latestPostsByUser.values.toList();
    _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
    debugPrint('PostService: Loaded ${_posts.length} latest mock posts (one per user)');
  }

  // Stream posts for real-time updates (user and connections only)
  Stream<List<PostModel>> getPostsStream({String? currentUserId}) {
    if (!_isFirebaseAvailable) {
      return Stream.value(_posts);
    }
    
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    // Get user's connections
    return _firestore!
        .collection('connections')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((connectionsSnapshot) async {
      List<String> connectionUserIds = connectionsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dynamic raw = data['contactUserId'];
            return raw is String && raw.isNotEmpty ? raw : null;
          })
          .whereType<String>()
          .toList();
      
      // Add current user to the list
      connectionUserIds.add(currentUserId);
      
      if (connectionUserIds.isEmpty) {
        // No connections, only show user's own posts
        final userPostsSnapshot = await _firestore!
            .collection(_collection)
            .where('userId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .get();
        
        return userPostsSnapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();
      } else {
        // Get posts from user and their connections
        final postsSnapshot = await _firestore!
            .collection(_collection)
            .where('userId', whereIn: connectionUserIds)
            .orderBy('createdAt', descending: true)
            .get();
        
        return postsSnapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();
      }
    });
  }

  // Create a new post
  Future<String?> createPost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    String? imageUrl,
  }) async {
    if (!_isFirebaseAvailable) {
      // Mock post creation for demonstration
      _setLoading(true);
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
        likes: [],
        shares: [],
        commentsCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _posts.insert(0, newPost);
      _setLoading(false);
      notifyListeners();
      debugPrint('PostService: Mock post created');
      return newPost.id;
    }
    
    try {
      _setLoading(true);
      _error = null;
      
      debugPrint('PostService: Creating new post for user: $userName');
      
      final postData = {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'imageUrl': imageUrl,
        'likes': <String>[],
        'shares': <String>[],
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore!.collection(_collection).add(postData);
      
      debugPrint('PostService: Post created with ID: ${docRef.id}');
      // Optimistic UI: insert locally so it appears immediately
      try {
        final now = DateTime.now();
        final localPost = PostModel(
          id: docRef.id,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          content: content,
          imageUrl: imageUrl,
          likes: const <String>[],
          shares: const <String>[],
          commentsCount: 0,
          createdAt: now,
          updatedAt: now,
        );
        _posts.insert(0, localPost);
        notifyListeners();
      } catch (e) {
        debugPrint('PostService: Failed to insert local post: $e');
      }
      return docRef.id;
    } catch (e) {
      _error = e.toString();
      debugPrint('PostService: Error creating post: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to check if error is a network/transient error
  bool _isTransientError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unavailable') ||
           errorString.contains('network') ||
           errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('socket') ||
           errorString.contains('host');
  }

  // Like/Unlike a post with retry logic
  Future<bool> toggleLike(String postId, String userId) async {
    // Find the post index first
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) {
      debugPrint('PostService: Post not found: $postId');
      return false;
    }
    
    final post = _posts[postIndex];
    final isCurrentlyLiked = post.likes.contains(userId);
    
    // Optimistic update: Update UI immediately
    final newLikes = List<String>.from(post.likes);
    if (isCurrentlyLiked) {
      newLikes.remove(userId);
    } else {
      newLikes.add(userId);
    }
    
    // Update local posts array immediately for instant UI feedback
    _posts[postIndex] = post.copyWith(
      likes: newLikes,
      updatedAt: DateTime.now(),
    );
    notifyListeners(); // Immediate UI update
    
    if (!_isFirebaseAvailable) {
      // Mock like toggle - already updated above
      debugPrint('PostService: Mock like toggled for post: $postId');
      return true;
    }
    
    // Sync with Firestore in the background with retry logic
    const maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        debugPrint('PostService: Toggling like for post: $postId, user: $userId (attempt ${retryCount + 1}/$maxRetries)');
        
        final postRef = _firestore!.collection(_collection).doc(postId);
        
        await _firestore!.runTransaction((transaction) async {
          final postDoc = await transaction.get(postRef);
          
          if (!postDoc.exists) {
            throw Exception('Post not found');
          }
          
          final postData = postDoc.data()!;
          final List<String> likes = List<String>.from(postData['likes'] ?? []);
          
          if (isCurrentlyLiked) {
            likes.remove(userId);
          } else {
            likes.add(userId);
          }
          
          transaction.update(postRef, {
            'likes': likes,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
        
        debugPrint('PostService: Like toggled successfully');
        return true;
      } catch (e) {
        retryCount++;
        final isTransient = _isTransientError(e);
        
        // If it's a transient error and we have retries left, wait and retry
        if (isTransient && retryCount < maxRetries) {
          final delaySeconds = retryCount; // Exponential backoff: 1s, 2s, 3s
          debugPrint('PostService: Transient error (attempt $retryCount/$maxRetries), retrying in ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue; // Retry
        } else {
          // Non-transient error or max retries reached, revert and fail
          debugPrint('PostService: Error toggling like, reverting: $e');
          _posts[postIndex] = post; // Revert to original state
          notifyListeners();
          _error = e.toString();
          return false;
        }
      }
    }
    
    // Should never reach here, but just in case
    debugPrint('PostService: Max retries reached, reverting like');
    _posts[postIndex] = post; // Revert to original state
    notifyListeners();
    return false;
  }

  // Share a post
  Future<void> sharePost(String postId, String userId) async {
    if (!_isFirebaseAvailable) {
      // Mock share for demonstration
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final newShares = List<String>.from(post.shares);
        
        if (!newShares.contains(userId)) {
          newShares.add(userId);
          
          _posts[postIndex] = post.copyWith(
            shares: newShares,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
          debugPrint('PostService: Mock post shared');
        }
      }
      return;
    }
    
    try {
      debugPrint('PostService: Sharing post: $postId, user: $userId');
      
      final postRef = _firestore!.collection(_collection).doc(postId);
      
      await _firestore!.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }
        
        final postData = postDoc.data()!;
        final List<String> shares = List<String>.from(postData['shares'] ?? []);
        
        if (!shares.contains(userId)) {
          shares.add(userId);
          
          transaction.update(postRef, {
            'shares': shares,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      debugPrint('PostService: Post shared successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('PostService: Error sharing post: $e');
      notifyListeners();
    }
  }

  // Delete a post
  Future<void> deletePost(String postId, String userId) async {
    if (!_isFirebaseAvailable) {
      // Mock delete for demonstration
      _setLoading(true);
      await Future.delayed(const Duration(milliseconds: 500));
      
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1 && _posts[postIndex].userId == userId) {
        _posts.removeAt(postIndex);
        notifyListeners();
        debugPrint('PostService: Mock post deleted');
      }
      
      _setLoading(false);
      return;
    }
    
    try {
      _setLoading(true);
      _error = null;
      
      debugPrint('PostService: Deleting post: $postId');
      
      // First check if the user owns the post
      final postDoc = await _firestore!.collection(_collection).doc(postId).get();
      
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }
      
      final postData = postDoc.data()!;
      if (postData['userId'] != userId) {
        throw Exception('You can only delete your own posts');
      }
      
      await _firestore!.collection(_collection).doc(postId).delete();
      
      // Remove from local list
      _posts.removeWhere((post) => post.id == postId);
      
      debugPrint('PostService: Post deleted successfully');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('PostService: Error deleting post: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Update post content
  Future<bool> updatePost(String postId, String newContent, String userId) async {
    if (!_isFirebaseAvailable) {
      // Mock update for demonstration
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1 && _posts[postIndex].userId == userId) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          content: newContent,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
        debugPrint('PostService: Mock post updated');
        return true;
      }
      return false;
    }
    
    try {
      _setLoading(true);
      _error = null;
      
      debugPrint('PostService: Updating post: $postId');
      
      final postRef = _firestore!.collection(_collection).doc(postId);
      
      // Check if user owns the post
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }
      
      final postData = postDoc.data()!;
      if (postData['userId'] != userId) {
        throw Exception('You can only edit your own posts');
      }
      
      // Update the post
      await postRef.update({
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local posts array
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          content: newContent,
          updatedAt: DateTime.now(),
        );
      }
      
      debugPrint('PostService: Post updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('PostService: Error updating post: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get posts by a specific user
  Future<List<PostModel>> getUserPosts(String userId) async {
    if (!_isFirebaseAvailable) {
      // Mock user posts for demonstration
      final userPosts = _posts.where((post) => post.userId == userId).toList();
      debugPrint('PostService: Mock fetched ${userPosts.length} posts for user');
      return userPosts;
    }
    
    try {
      debugPrint('PostService: Fetching posts for user: $userId');
      
      final QuerySnapshot snapshot = await _firestore!
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final userPosts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
      
      debugPrint('PostService: Fetched ${userPosts.length} posts for user');
      return userPosts;
    } catch (e) {
      debugPrint('PostService: Error fetching user posts: $e');
      return [];
    }
  }

  // Search posts by content
  Future<List<PostModel>> searchPosts(String query) async {
    if (!_isFirebaseAvailable) {
      // Mock search for demonstration
      final searchResults = _posts.where((post) => 
        post.content.toLowerCase().contains(query.toLowerCase())
      ).toList();
      debugPrint('PostService: Mock found ${searchResults.length} posts matching query');
      return searchResults;
    }
    
    try {
      debugPrint('PostService: Searching posts with query: $query');
      
      final QuerySnapshot snapshot = await _firestore!
          .collection(_collection)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: query + 'z')
          .orderBy('content')
          .orderBy('createdAt', descending: true)
          .get();

      final searchResults = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
      
      debugPrint('PostService: Found ${searchResults.length} posts matching query');
      return searchResults;
    } catch (e) {
      debugPrint('PostService: Error searching posts: $e');
      return [];
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Avoid unnecessary updates
    _isLoading = loading;
    // Debounce notifyListeners for better performance
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      notifyListeners();
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Create a new post
    Future<String?> createNewPost({
      required String content,
      String? imagePath,
      required String userId,
      required String userName,
      String? userProfileImageUrl,
    }) async {
      try {
        _setLoading(true);
        _error = null;
        debugPrint('PostService: Creating new post for user: $userName');

        String? imageUrl;
        
        // Upload image if provided (with retry logic already implemented)
        if (imagePath != null && imagePath.isNotEmpty) {
          debugPrint('PostService: Uploading image...');
          imageUrl = await _uploadPostImage(imagePath, userId);
          if (imageUrl == null) {
            debugPrint('PostService: Image upload failed, continuing without image');
          }
        }

        final postId = DateTime.now().millisecondsSinceEpoch.toString();
        final now = DateTime.now();
        final post = PostModel(
          id: postId,
          userId: userId,
          userName: userName,
          userAvatar: userProfileImageUrl ?? (userName.isNotEmpty ? userName[0].toUpperCase() : 'U'),
          content: content,
          imageUrl: imageUrl,
          likes: [],
          shares: [],
          commentsCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        if (_isFirebaseAvailable && _firestore != null) {
          // Save to Firestore with retry logic
          const maxRetries = 3;
          int retryCount = 0;
          bool success = false;
          
          while (retryCount < maxRetries && !success) {
            try {
              debugPrint('PostService: Saving to Firestore... (attempt ${retryCount + 1}/$maxRetries)');
              
              // Add timeout to Firestore operation
              await _firestore!.collection(_collection).doc(postId).set(post.toFirestore()).timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw Exception('Firestore save timeout');
                },
              );
              
              debugPrint('PostService: Post saved to Firestore successfully');
              success = true;
            } catch (e) {
              retryCount++;
              final isTransient = _isTransientError(e);
              
              if (isTransient && retryCount < maxRetries) {
                final delaySeconds = retryCount;
                debugPrint('PostService: Transient error saving post (attempt $retryCount/$maxRetries), retrying in ${delaySeconds}s...');
                await Future.delayed(Duration(seconds: delaySeconds));
                continue; // Retry
              } else {
                // Non-transient error or max retries reached
                debugPrint('PostService: Error saving post to Firestore: $e');
                throw e; // Re-throw to be caught by outer catch
              }
            }
          }
          
          if (!success) {
            throw Exception('Failed to save post after $maxRetries attempts');
          }
          
          // Optimistic UI: Add to local list immediately so it appears right away
          debugPrint('PostService: Adding post to local list for immediate display...');
          _posts.insert(0, post);
          debugPrint('PostService: Post added to local list successfully');
        } else {
          // Add to mock posts
          debugPrint('PostService: Adding to mock posts...');
          _posts.insert(0, post);
          debugPrint('PostService: Post added to mock posts successfully');
        }

        notifyListeners();
        debugPrint('PostService: Post creation completed successfully');
        return postId;
      } catch (e) {
        debugPrint('PostService: Error creating post: $e');
        _error = 'Failed to create post: ${e.toString()}';
        notifyListeners();
        return null;
      } finally {
        _setLoading(false);
      }
    }

  // Upload post image to Firebase Storage with retry logic and timeout
  Future<String?> _uploadPostImage(String imagePath, String userId) async {
    if (!_isFirebaseAvailable) {
      // Return a mock URL for demonstration
      debugPrint('PostService: Mock image URL generated');
      return 'https://via.placeholder.com/400x300?text=Post+Image';
    }
    
    const maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final file = File(imagePath);
        if (!await file.exists()) {
          debugPrint('PostService: Image file not found: $imagePath');
          return null;
        }
        
        final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child(userId)
            .child(fileName);

        // Add timeout to upload operation
        await ref.putFile(file).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Image upload timeout');
          },
        );
        
        // Add timeout to get download URL
        final downloadUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Get download URL timeout');
          },
        );
        
        debugPrint('PostService: Image uploaded successfully');
        return downloadUrl;
      } catch (e) {
        retryCount++;
        final isTransient = _isTransientError(e);
        
        if (isTransient && retryCount < maxRetries) {
          final delaySeconds = retryCount;
          debugPrint('PostService: Transient error uploading image (attempt $retryCount/$maxRetries), retrying in ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue; // Retry
        } else {
          debugPrint('PostService: Error uploading image: $e');
          // Don't return mock URL on failure - return null so post can still be created without image
          return null;
        }
      }
    }
    
    debugPrint('PostService: Max retries reached for image upload');
    return null;
  }

  // Delete a post
  Future<bool> removePost(String postId) async {
    try {
      _setLoading(true);
      debugPrint('PostService: Deleting post $postId');

      if (_isFirebaseAvailable && _firestore != null) {
        await _firestore!.collection(_collection).doc(postId).delete();
        debugPrint('PostService: Post deleted from Firestore');
      } else {
        _posts.removeWhere((post) => post.id == postId);
        debugPrint('PostService: Post removed from mock posts');
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PostService: Error deleting post: $e');
      _error = 'Failed to delete post: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
