
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/status_model.dart';

/// Full‑screen Instagram‑style status viewer.
///
/// Uses the existing [StatusModel] data and only changes the
/// presentation/interaction – no backend or routing logic is modified.
class StatusViewerScreen extends StatefulWidget {
  final List<StatusModel> statuses;
  final int initialIndex;

  const StatusViewerScreen({
    super.key,
    required this.statuses,
    required this.initialIndex,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animationController;

  static const Duration _storyDuration = Duration(seconds: 5);

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.statuses.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    _animationController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNext();
        }
      });

    _startProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startProgress() {
    _animationController
      ..stop()
      ..reset()
      ..forward();
  }

  void _goToNext() {
    if (_currentIndex < widget.statuses.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      _startProgress();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      _startProgress();
    }
  }

  void _onTapDown(TapDownDetails details) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    // Tap left to go to previous, right to go to next – like Instagram.
    if (dx < width * 0.3) {
      _goToPrevious();
    } else if (dx > width * 0.7) {
      _goToNext();
    } else {
      // Center tap pauses / resumes.
      if (_animationController.isAnimating) {
        _animationController.stop();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _startProgress();
                },
                itemCount: widget.statuses.length,
                itemBuilder: (context, index) {
                  final status = widget.statuses[index];
                  return _buildStoryContent(status);
                },
              ),

              // Top progress bars + header
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Row(
                          children: List.generate(
                            widget.statuses.length,
                            (index) {
                              double value;
                              if (index < _currentIndex) {
                                value = 1.0;
                              } else if (index == _currentIndex) {
                                value = _animationController.value.clamp(0.0, 1.0);
                              } else {
                                value = 0.0;
                              }

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: _StoryProgressBar(value: value),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildHeader(widget.statuses[_currentIndex]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryContent(StatusModel status) {
    return Stack(
      children: [
        // Background image / gradient
        Positioned.fill(
          child: status.imageUrl != null
              ? Image.network(
                  status.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0F172A), Color(0xFF020617)],
                    ),
                  ),
                ),
        ),

        // Text overlay
        if (status.text != null && status.text!.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 80,
            child: Text(
              status.text!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(StatusModel status) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
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
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _timeAgo(status.createdAt),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dateTime) {
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

class _StoryProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0

  const _StoryProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(
            height: 3,
            color: Colors.white24,
          ),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: 3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}


