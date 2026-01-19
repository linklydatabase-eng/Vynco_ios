import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/connection_request_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../chat/chat_screen.dart';
import '../../services/notification_service.dart';
import '../../models/connection_request_model.dart';
import '../../widgets/connection_request_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.grey900,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.grey900),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Consumer2<AuthService, NotificationService>(
        builder: (context, authService, notificationService, child) {
          if (authService.user?.uid == null) {
            return const Center(
              child: Text(
                'Please log in to view notifications',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey600,
                ),
              ),
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getNotificationsStream(authService.user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final allNotifications = snapshot.data ?? [];
              final filteredNotifications = _filterNotifications(allNotifications, _selectedFilter);

              if (filteredNotifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No new notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                        final notification = filteredNotifications[index];
                        return Dismissible(
                          key: Key(notification['id'] ?? '$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          onDismissed: (_) {
                            _deleteNotification(notification['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notification deleted')),
                            );
                          },
                          child: _buildNotificationCard(notification, notificationService, context),
                        );
                      },
                    );
            },
          );
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      // Sort client-side to avoid composite index requirement
      list.sort((a, b) {
        final ta = a['timestamp'];
        final tb = b['timestamp'];
        DateTime da;
        DateTime db;
        if (ta is Timestamp) {
          da = ta.toDate();
        } else if (ta is DateTime) {
          da = ta;
        } else {
          da = DateTime.fromMillisecondsSinceEpoch(0);
        }
        if (tb is Timestamp) {
          db = tb.toDate();
        } else if (tb is DateTime) {
          db = tb;
        } else {
          db = DateTime.fromMillisecondsSinceEpoch(0);
        }
        return db.compareTo(da);
      });
      return list;
    });
  }

  List<Map<String, dynamic>> _filterNotifications(List<Map<String, dynamic>> notifications, String filter) {
    // First filter out self-notifications
    final filteredNotifications = notifications.where((notification) {
      final data = notification['data'] as Map<String, dynamic>?;
      if (data != null) {
        final senderId = data['senderId'];
        final receiverId = data['receiverId'];
        // Skip self-notifications
        if (senderId != null && receiverId != null && senderId == receiverId) {
          return false;
        }
      }
      return true;
    }).toList();
    
    if (filter == 'All') return filteredNotifications;
    
    return filteredNotifications.where((notification) {
      final type = notification['type'] ?? '';
      switch (filter) {
        case 'Connection Requests':
          return type == 'connection_request';
        case 'Messages':
          return type == 'message';
        case 'Posts':
          return type == 'post_like' || type == 'post_comment' || type == 'post_share';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, NotificationService notificationService, BuildContext context) {
    final type = notification['type'] ?? '';
    final isRead = notification['isRead'] ?? false;
    final timestamp = notification['timestamp'] as Timestamp?;
    final timeAgo = timestamp != null ? _getTimeAgo(timestamp.toDate()) : '';
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? notification['message'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? AppColors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? AppColors.grey200 : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _handleNotificationTap(notification, context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Notification icon
              _buildNotificationIcon(type),
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.grey500),
                onSelected: (String value) {
                  _handleNotificationAction(value, notification, notificationService);
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Mark as Read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'connection_request':
        icon = Icons.person_add;
        color = AppColors.primary;
        break;
      case 'message':
        icon = Icons.message;
        color = Colors.blue;
        break;
      case 'post_like':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'post_comment':
        icon = Icons.comment;
        color = Colors.orange;
        break;
      case 'post_share':
        icon = Icons.share;
        color = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.grey500;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationAction(String action, Map<String, dynamic> notification, NotificationService notificationService) {
    switch (action) {
      case 'mark_read':
        _markAsRead(notification['id']);
        break;
      case 'delete':
        _deleteNotification(notification['id']);
        break;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification, BuildContext context) async {
    final type = notification['type'] ?? '';
    final auth = Provider.of<AuthService>(context, listen: false);
    
    // Mark as read
    _markAsRead(notification['id']);

    // Navigate based on notification type
    switch (type) {
      case 'connection_request':
        // Delete the notification after opening connections
        _deleteNotification(notification['id']);
        context.go('/connections');
        break;
      case 'message':
        final data = notification['data'] as Map<String, dynamic>?;
        final currentUserId = auth.user?.uid;
        final senderId = data?['senderId'] as String?;
        final receiverId = data?['receiverId'] as String?;
        final otherUserId = currentUserId == senderId ? receiverId : senderId;
        if (otherUserId != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
          if (userDoc.exists) {
            final userModel = UserModel.fromFirestore(userDoc);
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatScreen(user: userModel)),
              );
            }
            break;
          }
        }
        // Fallback
        context.go('/home');
        break;
      case 'post_like':
      case 'post_comment':
      case 'post_share':
        // Navigate to home screen
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Go to Home tab to view the post'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
        break;
    }
  }

  void _markAsRead(String notificationId) {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  void _deleteNotification(String notificationId) {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}