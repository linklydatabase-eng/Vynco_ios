import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

class StatusStoriesBar extends StatelessWidget {
  const StatusStoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6, // 1 for add status + 5 for friends' statuses
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AddStatusStory();
          }
          return _FriendStatusStory(
            name: 'Friend ${index}',
            imageUrl: 'https://via.placeholder.com/60',
            hasNewStatus: index <= 2,
          );
        },
      ),
    );
  }
}

class _AddStatusStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.go('/status'),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.grey300,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.grey600,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your Status',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FriendStatusStory extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool hasNewStatus;

  const _FriendStatusStory({
    required this.name,
    required this.imageUrl,
    required this.hasNewStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Open story viewer
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: hasNewStatus ? AppColors.primary : AppColors.grey300,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  imageUrl,
                  width: 56,
                  height: 56,
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
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
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
}
