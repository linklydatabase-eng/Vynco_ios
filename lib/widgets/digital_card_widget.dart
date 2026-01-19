import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../constants/digital_card_themes.dart';

class DigitalCardWidget extends StatefulWidget {
  const DigitalCardWidget({super.key});

  @override
  State<DigitalCardWidget> createState() => _DigitalCardWidgetState();
}

class _DigitalCardWidgetState extends State<DigitalCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final userName = authService.userModel?.fullName ??
            authService.user?.displayName ??
            'User';
        final theme =
            DigitalCardThemes.themeById(authService.digitalCardTheme);
        
        return GestureDetector(
          onTap: _flipCard,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final isShowingFront = _animation.value < 0.5;
              final rotation = _animation.value * 3.14159; // 180 degrees in radians
              
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(rotation),
                child: isShowingFront
                    ? _buildFrontCard(userName, authService, theme)
                    : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159), // Flip the back card to correct orientation
                      child: _buildBackCard(authService, theme),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _extractLinkedInUsername(String linkedInUrl) {
    // Extract username from various LinkedIn URL formats
    // Examples: 
    // - https://www.linkedin.com/in/username
    // - www.linkedin.com/in/username
    // - linkedin.com/in/username
    // - /in/username
    // - just username
    
    if (linkedInUrl.isEmpty) return '';
    
    // Remove trailing slash
    linkedInUrl = linkedInUrl.trim().replaceAll(RegExp(r'/$'), '');
    
    // Check if it's just a username (no URL structure)
    if (!linkedInUrl.contains('/') && !linkedInUrl.contains('linkedin')) {
      return linkedInUrl;
    }
    
    // Extract username from /in/username pattern
    final match = RegExp(r'/in/([^/?]+)').firstMatch(linkedInUrl);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? linkedInUrl;
    }
    
    // If no match, return the original (might already be a username)
    return linkedInUrl;
  }

  Widget _buildFrontCard(
    String userName,
    AuthService authService,
    DigitalCardThemeData theme,
  ) {
    final position = authService.userModel?.position ?? '';
    final email =
        authService.userModel?.email ?? authService.user?.email ?? '';
    final linkedIn =
        authService.userModel?.socialLinks['linkedin'] ?? '';
    final profileImageUrl =
        authService.userModel?.profileImageUrl ?? authService.user?.photoURL;
    final bool isTextBright = theme.textPrimaryColor.computeLuminance() > 0.5;
    final Color badgeBackground =
        isTextBright ? Colors.black.withOpacity(0.25) : Colors.white.withOpacity(0.25);
    final Color overlayBackground =
        isTextBright ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.35);

    return Center(
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(
        maxWidth: 360,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor.withOpacity(0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.borderColor.withOpacity(0.18),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 3.5 / 2.2,
        child: Stack(
        children: [
          // Main content - Centered text
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // Job Title (Position)
                  if (position.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        position,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                  
                  const SizedBox(height: 10),
                  
                  // Email
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // LinkedIn Account
                  if (linkedIn.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // LinkedIn logo (using badge icon as LinkedIn representation)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: badgeBackground,
                              borderRadius: BorderRadius.circular(3),
                            ),
                                child: Text(
                              'in',
                                  style: TextStyle(
                                fontSize: 10,
                                    color: theme.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _extractLinkedInUsername(linkedIn),
                                  style: TextStyle(
                                fontSize: 12,
                                    color: theme.textSecondaryColor,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  const SizedBox(height: 14),
                  
                  // Tap instruction
                  Text(
                    'TAP FOR QR CODE',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textPrimaryColor.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // User Profile Picture - Top left corner
          Positioned(
            top: 16,
            left: 16,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: theme.textPrimaryColor.withOpacity(0.2),
              backgroundImage:
                  profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
              child: profileImageUrl == null
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    )
                  : null,
            ),
          ),
          
          // Green dot (top left) - moved down to avoid overlap
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
        ),
      ),
    ),
    );
  }

  Widget _buildBackCard(
    AuthService authService,
    DigitalCardThemeData theme,
  ) {
    final bool isTextBright = theme.textPrimaryColor.computeLuminance() > 0.5;
    final Color overlayBackground =
        isTextBright ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.35);

    return Center(
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(
        maxWidth: 360,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor.withOpacity(0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.borderColor.withOpacity(0.18),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 3.5 / 2.2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Code - adjusted size to prevent overflow on smaller screens
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 140,
                    maxHeight: 140,
                  ),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.white, width: 1), // White border for visibility on dark gradient
                  ),
                  child: Center(
                    child: QrImageView(
                      data: authService.user?.uid != null
                          ? 'vynco://user/${authService.user!.uid}'
                          : 'vynco://user/unknown',
                      version: QrVersions.auto,
                      size: 120,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tap to flip back instruction - smaller padding
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: overlayBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Tap to flip back',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

}
