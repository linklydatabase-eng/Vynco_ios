import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/status_model.dart';
import '../services/auth_service.dart';
import '../services/status_service.dart';

class StatusWidget extends StatefulWidget {
  final StatusModel status;
  final VoidCallback? onTap;

  const StatusWidget({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  State<StatusWidget> createState() => _StatusWidgetState();
}

class _StatusWidgetState extends State<StatusWidget> {
  bool _isViewed = false;

  @override
  void initState() {
    super.initState();
    _isViewed = widget.status.isViewed;
  }

  Future<void> _markAsViewed() async {
    if (_isViewed) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final statusService = StatusService();
      
      await statusService.markStatusAsViewed(
        widget.status.id,
        authService.user?.uid ?? '',
      );
      
      setState(() {
        _isViewed = true;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _markAsViewed();
        widget.onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isViewed ? AppColors.grey300 : AppColors.primary,
            width: _isViewed ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile picture with status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  backgroundImage: widget.status.userProfileImageUrl != null
                      ? NetworkImage(widget.status.userProfileImageUrl!)
                      : null,
                  child: widget.status.userProfileImageUrl == null
                      ? Text(
                          widget.status.userName.isNotEmpty 
                              ? widget.status.userName[0].toUpperCase() 
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Status indicator (colored ring)
                if (!_isViewed)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            
            // Status content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.status.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getTimeAgo(widget.status.createdAt),
                    style: const TextStyle(
                      color: AppColors.grey600,
                      fontSize: 12,
                    ),
                  ),
                  if (widget.status.text != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.status.text!,
                      style: TextStyle(
                        color: AppColors.grey700,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.status.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.grey100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.status.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.grey100,
                              child: const Icon(
                                Icons.image,
                                color: AppColors.grey400,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // View indicator
            Icon(
              _isViewed ? Icons.visibility : Icons.visibility_off,
              color: _isViewed ? AppColors.grey400 : AppColors.primary,
              size: 16,
            ),
          ],
        ),
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
