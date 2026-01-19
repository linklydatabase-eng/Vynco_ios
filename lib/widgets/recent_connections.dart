import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../screens/status/create_status_screen.dart';

class RecentConnections extends StatelessWidget {
  const RecentConnections({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock: Check if user has connections
    final hasConnections = false; // Set to true to show connections, false to show + button
    
    if (!hasConnections) {
      return _buildAddPeopleCard(context);
    }

    final connections = [
      {
        'name': 'Sarah Johnson',
        'company': 'Design Co.',
        'imageUrl': 'https://via.placeholder.com/40',
        'time': '2 hours ago',
      },
      {
        'name': 'Mike Chen',
        'company': 'Tech Startup',
        'imageUrl': 'https://via.placeholder.com/40',
        'time': '1 day ago',
      },
      {
        'name': 'Emily Davis',
        'company': 'Marketing Pro',
        'imageUrl': 'https://via.placeholder.com/40',
        'time': '2 days ago',
      },
    ];

    return Column(
      children: connections.map((connection) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    connection['imageUrl']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.grey200,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.grey500,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    connection['name']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    connection['company']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    connection['time']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Open chat
                    },
                    icon: const Icon(
                      Icons.message,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Call
                    },
                    icon: const Icon(
                      Icons.phone,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddPeopleCard(BuildContext context) {
    return _buildAddStatusCard(context);
  }

  Widget _buildAddStatusCard(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Get the first name from the user's full name
        String firstName = 'User';
        if (authService.userModel != null && authService.userModel!.fullName.isNotEmpty) {
          firstName = authService.userModel!.fullName.split(' ').first;
        } else if (authService.user != null && authService.user!.displayName != null) {
          firstName = authService.user!.displayName!.split(' ').first;
        }
        
        // Get the user's profile image
        final profileImageUrl = authService.userModel?.profileImageUrl ?? 
                             authService.user?.photoURL;
        
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateStatusScreen(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
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
                // User avatar with actual profile picture or gradient background
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: profileImageUrl == null ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF6B35), // Orange gradient start
                            Color(0xFFE55A4B), // Orange gradient end
                          ],
                        ) : null,
                      ),
                      child: profileImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.network(
                                profileImageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to gradient with initial if image fails to load
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF6B35),
                                          Color(0xFFE55A4B),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    // Plus icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF6B35),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFFFF6B35),
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share what you\'re up to',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
