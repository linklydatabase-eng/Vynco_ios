import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../models/status_model.dart';
import '../services/auth_service.dart';
import '../services/status_service.dart';
import '../screens/status/status_viewer_screen.dart';

class StatusStoriesWidget extends StatefulWidget {
  const StatusStoriesWidget({super.key});

  @override
  State<StatusStoriesWidget> createState() => _StatusStoriesWidgetState();
}

class _StatusStoriesWidgetState extends State<StatusStoriesWidget> {
  final StatusService _statusService = StatusService();

  @override
  void initState() {
    super.initState();
    // Opportunistic cleanup to ensure only <24h stories are retained
    _statusService.cleanupExpiredStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.user?.uid == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<List<StatusModel>>(
          stream: _statusService.getStatuses(authService.user!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 100,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Error loading statuses',
                    style: TextStyle(
                      color: AppColors.textSecondary, // Muted Gray for Secondary Text
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            final statuses = snapshot.data ?? [];
            
            // Group statuses by user
            final Map<String, List<StatusModel>> groupedStatuses = {};
            for (final status in statuses) {
              if (!groupedStatuses.containsKey(status.userId)) {
                groupedStatuses[status.userId] = [];
              }
              groupedStatuses[status.userId]!.add(status);
            }
            
            // Sort each user's statuses by creation time
            groupedStatuses.forEach((userId, userStatuses) {
              userStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            });
            
            // Get unique users list (first status of each user for display)
            final uniqueUsers = groupedStatuses.values.map((statuses) => statuses.first).toList();
            // Sort by most recent status
            uniqueUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: uniqueUsers.length + 1, // +1 for "Add Status" button
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddStatusStory();
                  }
                  
                  final userStatus = uniqueUsers[index - 1];
                  final userStatuses = groupedStatuses[userStatus.userId]!;
                  return _buildStatusStory(userStatus, userStatuses);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddStatusStory() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final String displayName = authService.userModel?.fullName ?? 
                               authService.user?.displayName ?? 
                               'User';
    final String? initialPhotoUrl = authService.userModel?.profileImageUrl ?? 
                                    authService.user?.photoURL;
    final String? uid = authService.user?.uid;

    // Listen to user doc so freshly uploaded profile photos show immediately.
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final String? photoUrl = data?['profileImageUrl'] as String?
          ?? initialPhotoUrl
          ?? FirebaseAuth.instance.currentUser?.photoURL;

        return Container(
          width: 90,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/status'),
                child: Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.grey300,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 140,
                                memCacheHeight: 140,
                              )
                            : _buildDefaultAvatar(displayName, size: 70),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary, // Muted Gray for Secondary Text
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusStory(StatusModel status, List<StatusModel> userStatuses) {
    final hasNewStatus = _hasNewStatus(status);
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOwnStatus = status.userId == authService.user?.uid;
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openStoryViewer(context, userStatuses, 0),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasNewStatus || isOwnStatus ? AppColors.primary : AppColors.grey300,
                  width: hasNewStatus || isOwnStatus ? 3 : 2,
                ),
              ),
              child: ClipOval(
                child: status.userProfileImageUrl != null && status.userProfileImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: status.userProfileImageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        memCacheHeight: 120,
                      )
                    : _buildDefaultAvatar(status.userName, size: 60),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _getDisplayName(status.userName),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary, // Muted Gray for Secondary Text
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String userName, {double size = 70}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }

  bool _hasNewStatus(StatusModel status) {
    // Consider status as "new" if it was created within the last 2 hours
    final now = DateTime.now();
    final twoHoursAgo = now.subtract(const Duration(hours: 2));
    return status.createdAt.isAfter(twoHoursAgo);
  }

  String _getDisplayName(String userName) {
    if (userName.length <= 8) return userName;
    return '${userName.substring(0, 8)}...';
  }

  void _openStoryViewer(BuildContext context, List<StatusModel> statuses, int initialIndex) {
    if (statuses.isEmpty) return;
    
    // Mark status as viewed when opening
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user?.uid != null) {
      for (final status in statuses) {
        _statusService.markStatusAsViewed(status.id, authService.user!.uid);
      }
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(
          statuses: statuses,
          initialIndex: initialIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
