import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/status_model.dart';
import '../services/auth_service.dart';
import '../services/status_service.dart';
import 'status_widget.dart';

class StatusListWidget extends StatefulWidget {
  const StatusListWidget({super.key});

  @override
  State<StatusListWidget> createState() => _StatusListWidgetState();
}

class _StatusListWidgetState extends State<StatusListWidget> {
  final StatusService _statusService = StatusService();

  @override
  void initState() {
    super.initState();
    _statusService.cleanupExpiredStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.user?.uid == null) {
          return const Center(
            child: Text('Please log in to view statuses'),
          );
        }

        return StreamBuilder<List<StatusModel>>(
          stream: _statusService.getStatuses(authService.user!.uid),
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
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading statuses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final statuses = snapshot.data ?? [];

            if (statuses.isEmpty) {
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
                      'Be the first to share a status!',
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                return StatusWidget(
                  status: status,
                  onTap: () {
                    // TODO: Navigate to status detail view
                    _showStatusDetail(context, status);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showStatusDetail(BuildContext context, StatusModel status) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey200),
                  ),
                ),
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
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status.text != null) ...[
                        Text(
                          status.text!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.grey900,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (status.imageUrl != null)
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.grey100,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              status.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
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
                    ],
                  ),
                ),
              ),
            ],
          ),
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
