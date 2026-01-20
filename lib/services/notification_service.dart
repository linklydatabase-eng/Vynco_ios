import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? _currentUserId; // Add current user ID tracking
  bool _isLoading = false;
  final List<Map<String, dynamic>> _notifications = [];
  final Set<String> _seenNotificationDocIds = <String>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _userNotifSub;
  bool _skipInitialNotificationBatch = false;
  Future<void> Function(Map<String, dynamic> data)? _onNotificationTapHandler;
  Map<String, dynamic>? _pendingNotificationTap;
  
  // Performance optimization: Debounce notifyListeners
  Timer? _debounceTimer;

  String? get fcmToken => _fcmToken;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get notifications => _notifications;
  
  // Check if there are unread notifications (excluding self-notifications)
  bool get hasUnreadNotifications => _notifications.any((notification) {
    // Skip self-notifications
    final data = notification['data'] as Map<String, dynamic>?;
    if (data != null) {
      final senderId = data['senderId'];
      final receiverId = data['receiverId'];
      if (senderId != null && receiverId != null && senderId == receiverId) {
        return false; // Skip self-notifications
      }
    }
    return notification['isRead'] == false || notification['isRead'] == null;
  });


  Future<void> initialize() async {
    try {
      _setLoading(true);
      debugPrint('🔔 Initializing notifications');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ User granted provisional permission');
      } else {
        debugPrint('❌ User declined or has not accepted permission');
        return;
      }

      // Ensure foreground presentation on iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');

      // Ensure current user id is set even before token save
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        setCurrentUserId(uid);
      }

      // Set up message handlers
      _setupMessageHandlers();
      
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    if (response.payload == null || response.payload!.isEmpty) {
      return;
    }
    try {
      final dynamic decoded = jsonDecode(response.payload!);
      if (decoded is Map<String, dynamic>) {
        _handleNotificationNavigation(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('❌ Error parsing notification payload: $e');
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Received foreground message: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Handle background messages when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 App opened from background message: ${message.notification?.title}');
      _handleBackgroundMessage(message);
    });

    // Handle messages when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 App opened from terminated state: ${message.notification?.title}');
        _handleBackgroundMessage(message);
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // ABSOLUTE FIRST CHECK: Block ALL self-notifications at the FCM level
    final senderId = message.data['senderId']?.toString();
    final receiverId = message.data['receiverId']?.toString();
    
    // Block if sender and receiver are the same (with trim check)
    if (senderId != null && receiverId != null && 
        (senderId == receiverId || senderId.trim() == receiverId.trim())) {
      debugPrint('🚫 ABSOLUTE BLOCK: Blocking self-notification in FCM handler - senderId: $senderId, receiverId: $receiverId');
      return;
    }
    
    // Block if sender is current user (with trim check)
    if (_currentUserId != null && senderId != null && 
        (senderId == _currentUserId || senderId.trim() == (_currentUserId?.trim()))) {
      debugPrint('🚫 ABSOLUTE BLOCK: Blocking notification in FCM - sender ($senderId) is current user ($_currentUserId)');
      return;
    }
    
    // Block if receiver is current user AND sender is also current user (double-check)
    if (_currentUserId != null && receiverId != null && senderId != null &&
        receiverId == _currentUserId && senderId == _currentUserId) {
      debugPrint('🚫 ABSOLUTE BLOCK: Blocking self-notification - both sender and receiver are current user');
      return;
    }
    
    // Show local notification or update UI
    final notification = {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? 'New Message',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'timestamp': DateTime.now(),
      'isRead': false,
    };
    
    _notifications.insert(0, notification);
    // Debounce notifyListeners to reduce rebuilds
    _debounceNotifyListeners();
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle navigation or other actions when app is opened from notification
    debugPrint('📱 Handling background message: ${message.data}');
    if (message.data.isNotEmpty) {
      _handleNotificationNavigation(Map<String, dynamic>.from(message.data));
    }
  }

  // Set current user ID for better notification filtering
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    debugPrint('🔑 NotificationService: Current user set to $userId');
    
    // Clean up any existing self-notifications from local list
    _cleanupSelfNotifications();

    // Reset notification caches for fresh session
    _seenNotificationDocIds.clear();
    _notifications.clear();
    _skipInitialNotificationBatch = true;
    notifyListeners();

    // Start listening to Firestore notifications for this user (to show local notifications)
    _userNotifSub?.cancel();
    _userNotifSub = _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (_skipInitialNotificationBatch) {
        for (final doc in snapshot.docs) {
          _seenNotificationDocIds.add(doc.id);
        }
        _skipInitialNotificationBatch = false;
        debugPrint('🧭 Initial notification batch recorded (${snapshot.docs.length} docs) without replaying alerts');
        return;
      }

      for (final doc in snapshot.docChanges) {
        if (doc.type != DocumentChangeType.added) continue;
        final id = doc.doc.id;
        if (_seenNotificationDocIds.contains(id)) continue;
        _seenNotificationDocIds.add(id);
        final data = doc.doc.data();
        if (data == null) continue;
        final payload = data['data'] as Map<String, dynamic>?;
        final senderId = payload?['senderId'];
        final receiverId = payload?['receiverId'];
        // Skip self notifications
        if (senderId != null && receiverId != null && senderId == receiverId) continue;
        // Only show if this device belongs to the receiver
        if (_currentUserId != null && receiverId == _currentUserId) {
          _showLocalNotification({
            'title': data['title'],
            'body': data['body'],
            'data': payload ?? <String, dynamic>{},
          });
        }
      }
    });
  }

  // Clean up self-notifications from local list
  void _cleanupSelfNotifications() {
    _notifications.removeWhere((notification) {
      final data = notification['data'] as Map<String, dynamic>?;
      if (data != null) {
        final senderId = data['senderId'];
        final receiverId = data['receiverId'];
        return senderId != null && receiverId != null && senderId == receiverId;
      }
      return false;
    });
    notifyListeners();
    debugPrint('🧹 Cleaned up self-notifications from local list');
  }

  Future<void> saveTokenToFirestore(String userId) async {
    if (_fcmToken == null) return;

    try {
      debugPrint('💾 Saving FCM token for $userId');
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'lastSeen': FieldValue.serverTimestamp(),
        'notificationEnabled': true, // Add flag to control notifications
      });
      // Also set current user ID and clean up self-notifications
      setCurrentUserId(userId);
      // Clean up existing self-notifications from Firestore
      await cleanupSelfNotificationsFromFirestore(userId);
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  // Temporarily disable notifications for current user
  Future<void> disableNotificationsForUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationEnabled': false,
        'fcmToken': null, // Remove FCM token to prevent server-side notifications
      });
      debugPrint('🚫 NUCLEAR: Disabled notifications for user $userId');
    } catch (e) {
      debugPrint('❌ Error disabling notifications: $e');
    }
  }

  // Re-enable notifications for current user
  Future<void> enableNotificationsForUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationEnabled': true,
        'fcmToken': _fcmToken,
      });
      debugPrint('✅ Re-enabled notifications for user $userId');
    } catch (e) {
      debugPrint('❌ Error enabling notifications: $e');
    }
  }

  Future<void> sendMessageNotification({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String messageText,
    String? senderProfileImageUrl,
  }) async {
    // ABSOLUTE FIRST CHECK: Return immediately if sender == receiver (before any processing)
    if (senderId == receiverId || senderId.trim() == receiverId.trim()) {
      debugPrint('🚫 ABSOLUTE BLOCK: Self-notification blocked immediately - senderId: $senderId, receiverId: $receiverId');
      return;
    }
    
    try {

      // Block if receiver matches sender (already checked above, but extra safety)
      if (receiverId == senderId) {
        debugPrint('🚫 CRITICAL: Blocking notification - receiver and sender are the same: $senderId');
        return;
      }

      // Create notification data
      final notificationData = {
        'title': 'New message from $senderName',
        'body': messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText,
        'data': {
          'type': 'message',
          'senderId': senderId,
          'senderName': senderName,
          'receiverId': receiverId,
          'messageText': messageText,
          'timestamp': DateTime.now().toIso8601String(),
        }
      };

      // Save notification to Firestore
      await _saveNotificationToFirestore(receiverId, notificationData);

      // Try to send FCM notification (for when app is in background)
      // Note: Implementation may require a server key; this call is safe no-op if token missing
      await _sendFCMNotificationToUser(receiverId, notificationData);

    } catch (e) {
      debugPrint('❌ Error sending message notification: $e');
    }
  }

  Future<void> _showLocalNotification(Map<String, dynamic> notificationData) async {
    try {
      // Double-check: Don't show local notification for self-messages
      final data = notificationData['data'] as Map<String, dynamic>?;
      if (data != null) {
        final senderId = data['senderId'];
        final receiverId = data['receiverId'];
        
        // Block if sender and receiver are the same
        if (senderId != null && receiverId != null && senderId == receiverId) {
          debugPrint('🚫 Skipping local notification for self-message from sender: $senderId');
          return;
        }
        
        // Block if sender is current user
        if (_currentUserId != null && senderId != null && senderId == _currentUserId) {
          debugPrint('🚫 Skipping local notification - sender is current user: $_currentUserId');
          return;
        }
        
        // Block if receiver is not current user (can't notify yourself)
        if (_currentUserId != null && receiverId != null && receiverId == _currentUserId && senderId == _currentUserId) {
          debugPrint('🚫 Skipping local notification - self-message detected');
          return;
        }
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'messages',
        'Message Notifications',
        channelDescription: 'Notifications for new messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notificationData['title'],
        notificationData['body'],
        platformChannelSpecifics,
        payload: jsonEncode(notificationData['data']),
      );

      debugPrint('📱 Local notification shown: ${notificationData['title']}');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  void registerOnNotificationTapHandler(Future<void> Function(Map<String, dynamic> data) handler) {
    _onNotificationTapHandler = handler;
    if (_pendingNotificationTap != null) {
      final pending = _pendingNotificationTap!;
      _pendingNotificationTap = null;
      handler(pending);
    }
  }

  void unregisterOnNotificationTapHandler() {
    _onNotificationTapHandler = null;
  }

  Future<void> _emitNotificationTap(Map<String, dynamic> data) async {
    final handler = _onNotificationTapHandler;
    if (handler != null) {
      try {
        await handler(data);
      } catch (e) {
        debugPrint('❌ Error executing notification tap handler: $e');
      }
    } else {
      _pendingNotificationTap = data;
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'message') {
      _emitNotificationTap(data);
    }
  }

  Future<void> _sendFCMNotificationToUser(String receiverId, Map<String, dynamic> notificationData) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) {
        debugPrint('❌ Receiver not found: $receiverId');
        return;
      }

      final receiverData = receiverDoc.data()!;
      final receiverFcmToken = receiverData['fcmToken'] as String?;
      
      if (receiverFcmToken == null) {
        debugPrint('❌ Receiver FCM token not found');
        return;
      }

      // Send FCM notification
      await _sendFCMNotification(receiverFcmToken, notificationData);
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
    }
  }

  Future<void> _sendFCMNotification(String fcmToken, Map<String, dynamic> notificationData) async {
    try {
      // You'll need to implement server-side FCM sending or use a service
      // For now, we'll simulate the notification
      debugPrint('📤 Sending FCM notification to: $fcmToken');
      debugPrint('📤 Notification: ${notificationData['title']}');
      
      // In a real implementation, you would send this to your server
      // which would then send the FCM notification
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
    }
  }

  Future<void> _saveNotificationToFirestore(String receiverId, Map<String, dynamic> notificationData) async {
    try {
      // Double-check: Don't save self-notifications to Firestore
      final data = notificationData['data'] as Map<String, dynamic>?;
      if (data != null) {
        final senderId = data['senderId'];
        
        // Block if sender and receiver are the same
        if (senderId != null && senderId == receiverId) {
          debugPrint('🚫 Skipping saving self-notification to Firestore for sender: $senderId');
          return;
        }
      }

      await _firestore.collection('notifications').add({
        'receiverId': receiverId,
        'title': notificationData['title'],
        'body': notificationData['body'],
        'data': notificationData['data'],
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'message',
      });
    } catch (e) {
      debugPrint('❌ Error saving notification to Firestore: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'],
          'body': data['body'],
          'data': data['data'],
          'timestamp': data['timestamp'],
          'isRead': data['isRead'] ?? false,
          'type': data['type'],
        };
      }).toList();
      
      // Sort by timestamp in descending order (newest first)
      notifications.sort((a, b) {
        final timestampA = a['timestamp'];
        final timestampB = b['timestamp'];
        
        if (timestampA == null && timestampB == null) return 0;
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;
        
        DateTime dateTimeA;
        DateTime dateTimeB;
        
        if (timestampA is Timestamp) {
          dateTimeA = timestampA.toDate();
        } else if (timestampA is DateTime) {
          dateTimeA = timestampA;
        } else {
          return 0;
        }
        
        if (timestampB is Timestamp) {
          dateTimeB = timestampB.toDate();
        } else if (timestampB is DateTime) {
          dateTimeB = timestampB;
        } else {
          return 0;
        }
        
        return dateTimeB.compareTo(dateTimeA);
      });
      
      return notifications;
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      debugPrint('✅ Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Clean up self-notifications from Firestore
  Future<void> cleanupSelfNotificationsFromFirestore(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .get();

      int deletedCount = 0;
      for (final doc in notifications.docs) {
        final data = doc.data();
        final notificationData = data['data'] as Map<String, dynamic>?;
        if (notificationData != null) {
          final senderId = notificationData['senderId'];
          final receiverId = notificationData['receiverId'];
          if (senderId != null && receiverId != null && senderId == receiverId) {
            batch.delete(doc.reference);
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        debugPrint('🧹 Cleaned up $deletedCount self-notifications from Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up self-notifications from Firestore: $e');
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Avoid unnecessary updates
    _isLoading = loading;
    _debounceNotifyListeners();
  }
  
  void _debounceNotifyListeners() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _userNotifSub?.cancel();
    super.dispose();
  }
}

// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Handling a background message: ${message.messageId}');
}