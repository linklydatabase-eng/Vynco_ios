import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/status_service.dart';
import '../../models/status_model.dart';
import 'create_status_screen.dart';
import 'status_viewer_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final StatusService _statusService = StatusService();

  @override
  void initState() {
    super.initState();
    // Clean up expired statuses (older than 24h) when opening the screen
    _statusService.cleanupExpiredStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.grey900),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: const Text(
          'Status',
          style: TextStyle(
            color: AppColors.grey900,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateStatusScreen(),
                ),
              );
            },
            tooltip: 'Create new status',
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.user?.uid == null) {
            return const Center(
              child: Text('Please log in to view your statuses'),
            );
          }

          // Combine own statuses and connection statuses
          return StreamBuilder<List<StatusModel>>(
            stream: _statusService.getUserStatuses(authService.user!.uid),
            builder: (context, ownStatusesSnapshot) {
              return StreamBuilder<List<StatusModel>>(
                stream: _statusService.getStatuses(authService.user!.uid),
                builder: (context, connectionStatusesSnapshot) {
                  if (ownStatusesSnapshot.connectionState == ConnectionState.waiting ||
                      connectionStatusesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Combine and deduplicate statuses
                  final ownStatuses = ownStatusesSnapshot.data ?? [];
                  final connectionStatuses = connectionStatusesSnapshot.data ?? [];
                  final allStatuses = <StatusModel>[];
                  final seenIds = <String>{};
                  
                  // Add own statuses first
                  for (final status in ownStatuses) {
                    if (!seenIds.contains(status.id)) {
                      allStatuses.add(status);
                      seenIds.add(status.id);
                    }
                  }
                  
                  // Add connection statuses
                  for (final status in connectionStatuses) {
                    if (!seenIds.contains(status.id)) {
                      allStatuses.add(status);
                      seenIds.add(status.id);
                    }
                  }
                  
                  // Sort by creation time
                  allStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  // Group statuses by user for stories display
                  final Map<String, List<StatusModel>> groupedStatuses = {};
                  for (final status in allStatuses) {
                    if (!groupedStatuses.containsKey(status.userId)) {
                      groupedStatuses[status.userId] = [];
                    }
                    groupedStatuses[status.userId]!.add(status);
                  }
                  
                  // Sort each user's statuses
                  groupedStatuses.forEach((userId, userStatuses) {
                    userStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  });
                  
                  // Get unique users (first status of each user)
                  final uniqueUsers = groupedStatuses.values.map((statuses) => statuses.first).toList();
                  uniqueUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (allStatuses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 64,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No statuses yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Share what you\'re up to!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CreateStatusScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Status'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Stories bar at the top (Instagram style)
                      _buildStoriesBar(context, uniqueUsers, groupedStatuses, authService.user!.uid),
                      
                      // Status list below
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: allStatuses.length,
                          itemBuilder: (context, index) {
                            final status = allStatuses[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.95, end: 1.0),
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              builder: (context, scale, child) {
                                return AnimatedOpacity(
                                  duration: const Duration(milliseconds: 220),
                                  opacity: 1.0,
                                  child: Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildStatusCard(status),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(StatusModel status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFDFE), Color(0xFFF7FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  backgroundImage: status.userProfileImageUrl != null
                      ? NetworkImage(status.userProfileImageUrl!)
                      : null,
                  child: status.userProfileImageUrl == null
                      ? Text(
                          status.userName.isNotEmpty 
                              ? status.userName[0].toUpperCase() 
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                      ),
                      Text(
                        _getTimeAgo(status.createdAt),
                        style: const TextStyle(
                          color: AppColors.grey600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteStatus(status);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
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
          
          // Content
          if (status.text != null && status.text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                status.text!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.grey900,
                ),
              ),
            ),
          
          // Image
          if (status.imageUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.grey100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/placeholder.png',
                  image: status.imageUrl!,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.grey100,
                      child: const Icon(
                        Icons.image,
                        color: AppColors.grey400,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.grey500,
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires ${_getTimeUntilExpiry(status.expiresAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteStatus(StatusModel status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: const Text('Are you sure you want to delete this status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _statusService.deleteStatus(status.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting status: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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

  String _getTimeUntilExpiry(DateTime expiryTime) {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours}h';
    } else {
      return 'in ${difference.inDays}d';
    }
  }

  Widget _buildStoriesBar(
    BuildContext context,
    List<StatusModel> uniqueUsers,
    Map<String, List<StatusModel>> groupedStatuses,
    String currentUserId,
  ) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final String displayName = authService.userModel?.fullName ?? 
                               authService.user?.displayName ?? 
                               'User';
    final String? photoUrl = authService.userModel?.profileImageUrl ?? 
                            authService.user?.photoURL;
    final ownStatuses = groupedStatuses[currentUserId] ?? [];

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: uniqueUsers.length + 1, // +1 for "Add Status" button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Your Status button - shows own statuses or allows creating new one
            final hasOwnStatuses = ownStatuses.isNotEmpty;
            
            return Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (hasOwnStatuses) {
                        // View own statuses
                        _openStoryViewer(context, ownStatuses, 0);
                      } else {
                        // Create new status
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateStatusScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasOwnStatuses ? AppColors.primary : AppColors.grey300,
                          width: hasOwnStatuses ? 3 : 2,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipOval(
                            child: photoUrl != null && photoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => _buildDefaultAvatar(displayName),
                                    errorWidget: (context, url, error) => _buildDefaultAvatar(displayName),
                                  )
                                : _buildDefaultAvatar(displayName),
                          ),
                          if (!hasOwnStatuses)
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
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Your Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }

          final userStatus = uniqueUsers[index - 1];
          // Skip own status as it's already shown first
          if (userStatus.userId == currentUserId) {
            return const SizedBox.shrink();
          }
          
          final userStatuses = groupedStatuses[userStatus.userId] ?? [];
          final hasNewStatus = _hasNewStatus(userStatus);

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
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasNewStatus ? AppColors.primary : AppColors.grey300,
                          width: hasNewStatus ? 3 : 2,
                        ),
                      ),
                    child: ClipOval(
                      child: userStatus.userProfileImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: userStatus.userProfileImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildDefaultAvatar(userStatus.userName),
                              errorWidget: (context, url, error) => _buildDefaultAvatar(userStatus.userName),
                            )
                          : _buildDefaultAvatar(userStatus.userName),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getDisplayName(userStatus.userName),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar(String userName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  bool _hasNewStatus(StatusModel status) {
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
}
