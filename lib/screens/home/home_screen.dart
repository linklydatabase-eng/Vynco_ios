import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/notification_service.dart';
import '../../models/post_model.dart';
import '../../utils/responsive_utils.dart';
import '../connections/connections_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/digital_card_widget.dart';
import '../connections/qr_scanner_screen.dart';
import '../../widgets/create_post_modal.dart';
import '../../widgets/status_stories_widget.dart';
import '../../utils/haptics.dart';
import '../chat/chat_screen.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _navAnimationController;
  late final PageController _pageController = PageController(initialPage: _selectedIndex);

  final List<Widget> _screens = [
    const HomeDashboard(),
    const ConnectionsScreen(),
    const GroupsScreen(),
    const ProfileEditScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _navAnimationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
    Haptics.navSelection();
  }

  @override
  void dispose() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    notificationService.unregisterOnNotificationTapHandler();
    _navAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      if (authService.isAuthenticated && authService.user != null) {
        // Initialize notifications
        await notificationService.initialize();
        
        // Save FCM token to user's document
        await notificationService.saveTokenToFirestore(authService.user!.uid);
        notificationService.registerOnNotificationTapHandler(_handleNotificationNavigation);
        
        debugPrint('🔔 Notifications initialized for user: ${authService.user!.uid}');
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (index != _selectedIndex) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildAnimatedBottomNavBar(),
    );
  }

  Widget _buildAnimatedBottomNavBar() {
    final mediaQuery = MediaQuery.of(context);
    final bool isCompactWidth = mediaQuery.size.width <= 360;
    final double bottomInset = mediaQuery.viewPadding.bottom;
    final double horizontalPadding = isCompactWidth ? 10 : 16;
    final double verticalPadding = isCompactWidth ? 0 : 6;
    final double navHeight = (isCompactWidth ? 42 : 60) + (bottomInset > 0 ? 4 : 0);
    final double indicatorHeight = isCompactWidth ? 20 : 36;
    final double indicatorTop = isCompactWidth ? 4 : 8;
    final double indicatorRadius = isCompactWidth ? 12 : 16;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        isCompactWidth ? 10 : 16,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth =
              constraints.maxWidth - (isCompactWidth ? 2 : 0);
          final double itemWidth = availableWidth / _screens.length;
          final double outerHorizontalPadding = isCompactWidth ? 4 : 6;
          final double innerHorizontalPadding = isCompactWidth ? 6 : 8;
          final double adjustedIndicatorWidth =
              (itemWidth - innerHorizontalPadding * 2).clamp(0.0, itemWidth);

            return Container(
              height: navHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF091021).withOpacity(0.62),
                border: Border.all(color: Colors.white.withOpacity(0.02)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF020609).withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: outerHorizontalPadding),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: isCompactWidth ? 1 : 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0x1A6A7EFF),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: innerHorizontalPadding),
                            child: Row(
                              children: [
                                _buildNavItem(
                                  0,
                                  Icons.home_outlined,
                                  Icons.home,
                                  'Home',
                                  isCompact: isCompactWidth,
                                ),
                                _buildNavItem(
                                  1,
                                  Icons.people_outlined,
                                  Icons.people,
                                  'Connections',
                                  isCompact: isCompactWidth,
                                ),
                                _buildNavItem(
                                  2,
                                  Icons.group_work_outlined,
                                  Icons.group_work,
                                  'Groups',
                                  isCompact: isCompactWidth,
                                ),
                                _buildNavItem(
                                  3,
                                  Icons.person_outlined,
                                  Icons.person,
                                  'Profile',
                                  isCompact: isCompactWidth,
                                ),
                                _buildNavItem(
                                  4,
                                  Icons.settings_outlined,
                                  Icons.settings,
                                  'Settings',
                                  isCompact: isCompactWidth,
                                ),
                              ].map((child) => Expanded(child: child)).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleNotificationNavigation(Map<String, dynamic> data) async {
    if (!mounted) return;
    if (data['type']?.toString() != 'message') {
      return;
    }

    final senderId = data['senderId']?.toString();
    if (senderId == null || senderId.isEmpty) {
      return;
    }

    try {
      UserModel userModel;
      final senderDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();

      if (senderDoc.exists) {
        userModel = UserModel.fromFirestore(senderDoc);
      } else {
        final fallbackName = data['senderName']?.toString() ?? 'Contact';
        String fallbackUsername = fallbackName.replaceAll(' ', '').toLowerCase();
        if (fallbackUsername.isEmpty) {
          fallbackUsername = 'user_${DateTime.now().millisecondsSinceEpoch}';
        }
        userModel = UserModel(
          uid: senderId,
          email: '',
          fullName: fallbackName,
          username: fallbackUsername,
          profileImageUrl: null,
          company: null,
          position: null,
          bio: null,
          phoneNumber: null,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: false,
        );
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(user: userModel),
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to navigate to chat from notification: $e');
    }
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    required bool isCompact,
  }) {
    final isSelected = _selectedIndex == index;
    final bool showLabel = !isCompact;
    final double verticalItemPadding = isCompact ? 0 : 12;
    final double iconPadding = isSelected
        ? (isCompact ? 3.5 : 9)
        : (isCompact ? 2.5 : 7);
    final double iconSize = isSelected
        ? (isCompact ? 17 : 26)
        : (isCompact ? 15 : 23);
    final double spacing = showLabel ? 6 : 0;
    
    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        splashColor: AppColors.primary.withOpacity(0.2),
        highlightColor: Colors.transparent,
        onTap: () async {
          if (_selectedIndex != index) {
            await Haptics.navSelection();
            _navAnimationController.reset();
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
            _navAnimationController.forward();
          }
        },
        child: SizedBox(
          height: isCompact ? 48 : 64,
          child: Center(
            child: _NavItemContent(
              isSelected: isSelected,
              icon: isSelected ? activeIcon : icon,
              iconPadding: iconPadding,
              iconSize: iconSize,
              showLabel: showLabel,
              spacing: spacing,
              label: label,
              isCompact: isCompact,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemContent extends StatelessWidget {
  const _NavItemContent({
    required this.isSelected,
    required this.icon,
    required this.iconPadding,
    required this.iconSize,
    required this.showLabel,
    required this.spacing,
    required this.label,
    required this.isCompact,
  });

  final bool isSelected;
  final IconData icon;
  final double iconPadding;
  final double iconSize;
  final bool showLabel;
  final double spacing;
  final String label;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final Color activeGlow = const Color(0xFF38BDF8);
    final Color idleGlow = const Color(0x331E293B);
    final double translateY = isSelected ? -6 : 0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()..translate(0.0, translateY),
            margin: EdgeInsets.only(bottom: showLabel ? spacing : 0),
            padding: EdgeInsets.all(isCompact ? iconPadding * 0.9 : iconPadding),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF1E3A8A).withOpacity(0.35)
                  : idleGlow,
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? activeGlow : idleGlow)
                      .withOpacity(isSelected ? 0.45 : 0.25),
                  blurRadius: isSelected ? 22 : 14,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.12 : 0.94,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Icon(
                icon,
                key: ValueKey('${icon.codePoint}-$isSelected'),
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                size: isCompact ? iconSize * 0.95 : iconSize,
              ),
            ),
          ),
          if (showLabel) ...[
            SizedBox(height: spacing),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFFCBD5F5).withOpacity(0.8),
                fontSize: isSelected ? 13 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
                height: 1.2,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with TickerProviderStateMixin {
  int _selectedTab = 0; // 0 for Feeds, 1 for Digital Card
  late AnimationController _tabAnimationController;
  late AnimationController _slideAnimationController;
  double _pageOffset = 0.0; // Track page scroll position for smooth indicator animation (0.0 = Feeds, 1.0 = Digital Card)
  late ScrollController _scrollController;
  double _scrollOffset = 0.0; // Track scroll position for fade effect
  bool _hasLoadedInitialPosts = false; // Flag to prevent multiple initial loads
  bool _isInitialLoading = false; // Flag to track if initial load is in progress

  bool _isValidAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.hasAuthority;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    
    // Load posts only once when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedInitialPosts) {
        _loadPostsOnce();
      }
    });
  }

  Future<void> _loadPostsOnce() async {
    if (_isInitialLoading) return; // Prevent multiple calls
    
    final postService = Provider.of<PostService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Only load if posts list is empty and we're not already loading
    if (postService.posts.isEmpty && !postService.isLoading) {
      if (mounted) {
        setState(() {
          _isInitialLoading = true;
        });
      }
      
      await postService.getPosts(currentUserId: authService.user?.uid);
      
      // Mark as loaded after the initial load completes (success or failure)
      if (mounted) {
        setState(() {
          _hasLoadedInitialPosts = true;
          _isInitialLoading = false;
        });
      }
    } else {
      // Posts already loaded or loading, mark as done
      if (mounted) {
        setState(() {
          _hasLoadedInitialPosts = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey900, // Overall Background
      appBar: AppBar(
        backgroundColor: AppColors.grey800, // Sidebar/AppBar Background
        elevation: 0,
        surfaceTintColor: AppColors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Vynco',
          style: TextStyle(
            color: AppColors.textPrimary, // Bright White Text
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // Notification bell
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              return Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight, // Light Blue
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.white, size: 20), // White Icon
                      onPressed: () => context.go('/notifications'),
                    ),
                  ),
                  if (notificationService.hasUnreadNotifications)
                    Positioned(
                      right: 14,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Content area that slides horizontally - takes full screen
            GestureDetector(
                onHorizontalDragStart: (_) {
                  // Stop ongoing animation so user-driven drag feels responsive
                  if (_slideAnimationController.isAnimating) {
                    _slideAnimationController.stop();
                  }
                },
                onHorizontalDragUpdate: (details) {
                  // Only handle horizontal drag if not actively scrolling vertically
                  if (_scrollController.hasClients && _scrollController.offset > 10) {
                    return;
                  }
                  final screenWidth = MediaQuery.of(context).size.width;
                  // Increase sensitivity slightly for more responsive drag feel
                  final delta = (details.delta.dx / screenWidth) * 1.1;
                  setState(() {
                    _pageOffset = (_pageOffset - delta).clamp(0.0, 1.0);
                  });
                },
                onHorizontalDragEnd: (details) {
                  // Only handle horizontal drag end if not actively scrolling vertically
                  if (_scrollController.hasClients && _scrollController.offset > 10) {
                    return;
                  }
                  final velocity = details.primaryVelocity ?? 0;
                  // Asymmetric commit thresholds for a more natural feel
                  const double toDigitalThreshold = 0.30; // commit to Digital Card (lowered for faster response)
                  const double toFeedsThresholdFromDigital = 0.85; // commit back to Feeds (lowered for faster response)

                  int targetTab;
                  double targetOffset;

                  // Strong velocity wins (lowered threshold for easier fast swipe detection)
                  if (velocity < -200) {
                    targetTab = 1;
                    targetOffset = 1.0;
                  } else if (velocity > 200) {
                    targetTab = 0;
                    targetOffset = 0.0;
                  } else {
                    // Decide by position with asymmetric thresholds based on current tab
                    if (_selectedTab == 1) {
                      // Currently on Digital Card: require only a tiny drag right to return
                      targetTab = _pageOffset < toFeedsThresholdFromDigital ? 0 : 1;
                    } else {
                      // Currently on Feeds: require more intent to go to Digital Card
                      targetTab = _pageOffset > toDigitalThreshold ? 1 : 0;
                    }
                    targetOffset = targetTab.toDouble();
                  }
                  
                  setState(() {
                    _selectedTab = targetTab;
                  });
                  
                  // Animate smoothly to target offset
                  final startOffset = _pageOffset;
                  _slideAnimationController.reset();
                  final animation = Tween<double>(begin: startOffset, end: targetOffset).animate(
                    CurvedAnimation(
                      parent: _slideAnimationController,
                      curve: Curves.easeOutCubic, // Faster, more responsive curve
                    ),
                  );
                  animation.addListener(() {
                    setState(() {
                      _pageOffset = animation.value;
                    });
                  });
                  _slideAnimationController.forward();
                  _tabAnimationController.forward().then((_) { 
                    _tabAnimationController.reset(); 
                  });
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    // Calculate horizontal offset: 0 = Feeds visible, -screenWidth = Digital Card visible
                    final horizontalOffset = -_pageOffset * screenWidth;
                    
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Feeds content - slides left when swiping right
                        Transform.translate(
                          offset: Offset(horizontalOffset, 0),
                          child: SizedBox(
                            width: screenWidth,
                            height: constraints.maxHeight,
                            child: _buildFeedsContentWrapper(),
                          ),
                        ),
                        // Digital Card content - slides in from right when swiping left
                        Transform.translate(
                          offset: Offset(horizontalOffset + screenWidth, 0),
                          child: SizedBox(
                            width: screenWidth,
                            height: constraints.maxHeight,
                            child: _buildDigitalCardContentWrapper(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            // Header, status, and tabs overlay on top (fade on scroll in Feeds mode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _selectedTab == 0 
                    ? (1.0 - (_scrollOffset / 100).clamp(0.0, 1.0))
                    : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const StatusStoriesWidget(),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, small: 2)),
                    _buildTabBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              heroTag: 'fab_create_post',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreatePostModal(),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Get the first name from the user's full name
        String firstName = 'User';
        if (authService.userModel != null && authService.userModel!.fullName.isNotEmpty) {
          firstName = authService.userModel!.fullName.split(' ').first;
          debugPrint('✅ Using userModel fullName: ${authService.userModel!.fullName}');
        } else if (authService.user != null && authService.user!.displayName != null && authService.user!.displayName!.isNotEmpty) {
          firstName = authService.user!.displayName!.split(' ').first;
          debugPrint('✅ Using Firebase user displayName: ${authService.user!.displayName}');
        } else {
          debugPrint('❌ No user name found - userModel: ${authService.userModel?.fullName}, Firebase user: ${authService.user?.displayName}');
        }
        
        return Padding(
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.getHorizontalPadding(context),
            ResponsiveUtils.getSpacing(context, small: 8),
            ResponsiveUtils.getHorizontalPadding(context),
            ResponsiveUtils.getSpacing(context, small: 8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName!',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, baseSize: 28),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, // Bright White Text
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, small: 4)),
                    Text(
                      'Ready to connect today?',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                        color: AppColors.textSecondary, // Muted Gray for Secondary Text
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
      },
    );
  }


  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        ResponsiveUtils.getHorizontalPadding(context),
        0,
        ResponsiveUtils.getHorizontalPadding(context),
        ResponsiveUtils.getSpacing(context, small: 1),
      ),
      decoration: BoxDecoration(
        color: AppColors.grey900, // Match background color
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          final indicatorPosition = _pageOffset.clamp(0.0, 1.0) * tabWidth;
          
          return Stack(
            children: [
              // Sliding yellow line indicator that follows swipe
              Positioned(
                left: indicatorPosition,
                bottom: 0,
                child: Container(
                  width: tabWidth,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),
              // Tab buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchToTab(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.getSpacing(context, small: 2),
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 100),
                          style: TextStyle(
                            color: _pageOffset < 0.5 ? AppColors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                            letterSpacing: -0.2,
                          ),
                          child: const Text(
                            'Feeds',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchToTab(1),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.getSpacing(context, small: 2),
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 100),
                          style: TextStyle(
                            color: _pageOffset >= 0.5 ? AppColors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                            letterSpacing: -0.2,
                          ),
                          child: const Text(
                            'Digital Card',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _switchToTab(int index) {
    setState(() {
      _selectedTab = index;
    });
    // Animate _pageOffset smoothly
    final targetOffset = index.toDouble();
    final startOffset = _pageOffset;
    _slideAnimationController.reset();
    final animation = Tween<double>(begin: startOffset, end: targetOffset).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: Curves.easeOutCubic, // Faster, more responsive curve
      ),
    );
    animation.addListener(() {
      setState(() {
        _pageOffset = animation.value;
      });
    });
    _slideAnimationController.forward();
    _tabAnimationController.forward().then((_) {
      _tabAnimationController.reset();
    });
  }


  // Wrapper around feeds content (only posts list, no headers)
  Widget _buildFeedsContentWrapper() {
    return Consumer<PostService>(
      builder: (context, postService, child) {
        // Show loading indicator during initial load
        if (_isInitialLoading || (postService.isLoading && postService.posts.isEmpty && !_hasLoadedInitialPosts)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading posts...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                  ),
                ),
              ],
            ),
          );
        }
        
        if (postService.error != null && postService.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
                const SizedBox(height: 16),
                Text(
                  'Unable to Load Posts', 
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 18), 
                    fontWeight: FontWeight.bold, 
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 8)),
                Text(
                  postService.error!, 
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14), 
                    color: AppColors.textSecondary,
                  ), 
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveUtils.getVerticalPadding(context)),
                ElevatedButton(
                  onPressed: () {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    postService.getPosts(currentUserId: authService.user?.uid);
                  },
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            final authService = Provider.of<AuthService>(context, listen: false);
            // Force refresh to bypass cache
            await postService.getPosts(currentUserId: authService.user?.uid, forceRefresh: true);
          },
          child: postService.posts.isEmpty
              ? ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: ResponsiveUtils.getVerticalPadding(context) * 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context)),
                      child: _buildEmptyPostsState(),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent: 500, // Cache more items for smoother scrolling
                  addAutomaticKeepAlives: false, // Don't keep items alive unnecessarily
                  addRepaintBoundaries: true, // Isolate repaints for better performance
                  itemCount: postService.posts.length + 1, // +1 for spacer
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Spacer for header height - allows posts to scroll to top
                      return SizedBox(
                        height: ResponsiveUtils.getVerticalPadding(context) * 20, // Header + status + tabs height with extra clearance
                      );
                    }
                    
                    final postIndex = index - 1;
                    if (postIndex >= postService.posts.length) {
                      return const SizedBox.shrink();
                    }
                    
                    final post = postService.posts[postIndex];
                    return RepaintBoundary(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: ResponsiveUtils.getHorizontalPadding(context),
                          right: ResponsiveUtils.getHorizontalPadding(context),
                          bottom: ResponsiveUtils.getVerticalPadding(context),
                        ),
                        child: _buildFeedPost(post, postIndex),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  // Wrapper around digital card content (only card content, no headers)
  Widget _buildDigitalCardContentWrapper() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 280), // Match header height for consistency
      physics: const ClampingScrollPhysics(), // Smooth scrolling physics
      child: _buildDigitalCardContent(),
    );
  }

  

  Widget _buildEmptyPostsState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Posts Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary, // Bright White Text
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something with your network!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CreatePostModal(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedPost(PostModel post, int index) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;
    final isLiked = currentUserId != null ? post.isLikedBy(currentUserId) : false;
    final isOwnPost = currentUserId != null && post.userId == currentUserId;
    
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getVerticalPadding(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F3A).withOpacity(0.6),
            const Color(0xFF23284A).withOpacity(0.5),
            const Color(0xFF2A2F50).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 24)),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: ResponsiveUtils.getPadding(context),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.oceanGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: ResponsiveUtils.getAvatarSize(context, small: 20, medium: 22, large: 24),
                    backgroundColor: AppColors.grey900.withOpacity(0.6),
                    backgroundImage: _isValidAvatarUrl(post.userAvatar)
                        ? NetworkImage(post.userAvatar)
                        : null,
                    child: _isValidAvatarUrl(post.userAvatar)
                        ? null
                        : Text(
                            post.userAvatar.isNotEmpty ? post.userAvatar[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.getFontSize(context, baseSize: 18),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getHorizontalPadding(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, baseSize: 17),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, small: 4)),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: ResponsiveUtils.getIconSize(context, baseSize: 14),
                            color: AppColors.grey400,
                          ),
                          SizedBox(width: ResponsiveUtils.getSpacing(context, small: 4)),
                          Text(
                            post.timeAgo,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context, baseSize: 13),
                              color: AppColors.grey400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Only show menu for user's own posts
                if (isOwnPost)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey800.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
                      border: Border.all(
                        color: AppColors.grey400.withOpacity(0.2),
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert, 
                        color: AppColors.grey300, 
                        size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                      ),
                      color: AppColors.surfaceDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deletePost(post, index);
                        } else if (value == 'edit') {
                          _editPost(post, index);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Edit caption',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Delete post',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Post content (only show if content is not empty)
          if (post.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context)),
              child: Text(
                post.content,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                  color: AppColors.textPrimary,
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          
          // Post image (if available)
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.getHorizontalPadding(context),
                ResponsiveUtils.getVerticalPadding(context),
                ResponsiveUtils.getHorizontalPadding(context),
                0,
              ),
              child: _AdaptiveImageContainer(
                imageUrl: post.imageUrl!,
              ),
            ),
          
          // Engagement metrics
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.getHorizontalPadding(context),
              ResponsiveUtils.getVerticalPadding(context),
              ResponsiveUtils.getHorizontalPadding(context),
              ResponsiveUtils.getSpacing(context, small: 8),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.grey800.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 20)),
                border: Border.all(
                  color: AppColors.grey400.withOpacity(0.05),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.getVerticalPadding(context) * 0.75,
                horizontal: ResponsiveUtils.getHorizontalPadding(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1F295B).withOpacity(0.5),
                                const Color(0xFF283B89).withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6B8FAE).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? AppColors.error : AppColors.textPrimary,
                                  size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                                  key: ValueKey(isLiked),
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.getSpacing(context, small: 6)),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  '${post.likes.length}',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                                    color: isLiked ? AppColors.error : AppColors.textPrimary,
                                    fontWeight: isLiked ? FontWeight.bold : FontWeight.w600,
                                  ),
                                  key: ValueKey('${post.likes.length}_$isLiked'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCommentsModal(post),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1F295B).withOpacity(0.5),
                                const Color(0xFF283B89).withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6B8FAE).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.comment_outlined, 
                                color: AppColors.textPrimary, 
                                size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                              ),
                              SizedBox(width: ResponsiveUtils.getSpacing(context, small: 6)),
                              Text(
                                '${post.commentsCount}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _sharePost(post),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 16)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getHorizontalPadding(context),
                            vertical: ResponsiveUtils.getVerticalPadding(context) * 0.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1F295B).withOpacity(0.5),
                                const Color(0xFF283B89).withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6B8FAE).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.share_outlined, 
                                color: AppColors.textPrimary, 
                                size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                              ),
                              SizedBox(width: ResponsiveUtils.getSpacing(context, small: 6)),
                              Text(
                                '${post.shares.length}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalCardContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your Digital Business Card',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary, // Bright White Text
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Share your professional identity in style',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary, // Muted Gray for Secondary Text
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Digital Card Widget
          const DigitalCardWidget(),
          
          const SizedBox(height: 8),
          
          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan QR Button - Floating style above Share and vCard
                Container(
                  width: 120,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary, // Orange background
                    borderRadius: BorderRadius.circular(26), // Pill shape
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () {
                        _showQRCode();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Scan QR',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Action buttons - only Share and vCard
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Share button (bluish glass effect)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1F295B).withOpacity(0.85),
                                  const Color(0xFF283B89).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6B8FAE).withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _shareDigitalCard();
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.share,
                                      color: AppColors.textPrimary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // vCard button (bluish glass effect)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1F295B).withOpacity(0.85),
                                  const Color(0xFF283B89).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6B8FAE).withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _generateVCard();
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.contact_page,
                                      color: AppColors.textPrimary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'vCard',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey100, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey100.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Like functionality
  void _toggleLike(int index) async {
    final postService = Provider.of<PostService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like posts')),
      );
      return;
    }
    
    final post = postService.posts[index];
    
    final success = await postService.toggleLike(post.id, currentUserId);
    
    if (!mounted) return;
    
    if (!success) {
      // Show error feedback only
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to like post. Please check your connection.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Comment functionality
  void _showCommentsModal(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(post: post),
    );
  }

  // Share functionality
  void _sharePost(PostModel post) {
    final postService = Provider.of<PostService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;
    
    if (currentUserId != null) {
      postService.sharePost(post.id, currentUserId);
    }
    
    // Show share options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareModal(post: post),
    );
  }

  // Delete post functionality
  void _deletePost(PostModel post, int index) {
    final postService = Provider.of<PostService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;
    
    if (currentUserId == null) return;
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Delete Post',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await postService.deletePost(post.id, currentUserId);
              // Refresh posts after deletion
              await postService.getPosts(currentUserId: currentUserId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // Edit post functionality
  void _editPost(PostModel post, int index) {
    final postService = Provider.of<PostService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid;
    
    if (currentUserId == null) return;
    
    final textController = TextEditingController(text: post.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Edit Caption',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: textController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new caption...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newContent = textController.text.trim();
              if (newContent.isNotEmpty && newContent != post.content) {
                Navigator.of(context).pop();
                // Update post content
                await postService.updatePost(post.id, newContent, currentUserId);
                // Refresh posts after edit
                await postService.getPosts(currentUserId: currentUserId);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to profile edit
  void _navigateToProfileEdit() {
    context.push('/profile-edit');
  }

  // Share digital card functionality
  void _shareDigitalCard() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userModel = authService.userModel;
    final user = authService.user;
    
    if (userModel == null && user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User information not available')),
      );
      return;
    }
    
    final userName = userModel?.fullName ?? user?.displayName ?? 'User';
    final userEmail = userModel?.email ?? user?.email ?? '';
    final userId = user?.uid ?? '';
    
    // Create shareable content
    final shareText = '''
🌟 Check out my digital business card!

👤 Name: $userName
📧 Email: $userEmail
🔗 Profile: vynco://user/$userId

Download Vynco to connect with me digitally!
''';
    
    Share.share(
      shareText,
      subject: 'My Digital Business Card - $userName',
    );
  }

  // Generate vCard functionality
  void _generateVCard() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userModel = authService.userModel;
    final user = authService.user;
    
    if (userModel == null && user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User information not available')),
      );
      return;
    }
    
    final userName = userModel?.fullName ?? user?.displayName ?? 'User';
    final userEmail = userModel?.email ?? user?.email ?? '';
    final userPhone = userModel?.phoneNumber ?? '';
    final userCompany = userModel?.company ?? '';
    final userPosition = userModel?.position ?? '';
    
    // Generate vCard content
    final vCardContent = '''BEGIN:VCARD
VERSION:3.0
FN:$userName
N:${userName.split(' ').last};${userName.split(' ').first};;;
EMAIL:$userEmail
${userPhone.isNotEmpty ? 'TEL:$userPhone' : ''}
${userCompany.isNotEmpty ? 'ORG:$userCompany' : ''}
${userPosition.isNotEmpty ? 'TITLE:$userPosition' : ''}
URL:vynco://user/${user?.uid ?? ''}
END:VCARD''';
    
    // Share the vCard
    Share.share(
      vCardContent,
      subject: 'Contact Card - $userName',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('vCard for $userName generated successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showQRCode() {
    // Show QR code in a dialog or navigate to QR screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(),
      ),
    );
  }


}

// Comments Modal
class CommentsModal extends StatefulWidget {
  final PostModel post;

  const CommentsModal({super.key, required this.post});

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      final comments = commentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['userName'] ?? 'User',
          'avatar': data['userAvatar'] ?? 'U',
          'content': data['content'] ?? '',
          'time': _formatTimestamp(data['createdAt']),
          'userId': data['userId'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'now';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'now';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Helper method to check if error is a network/transient error
  bool _isTransientError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unavailable') ||
           errorString.contains('network') ||
           errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('socket') ||
           errorString.contains('host');
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _isSubmittingComment) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.userModel;
    final currentUserId = authService.user?.uid;

    if (currentUser == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to comment'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final commentText = _commentController.text.trim();
    final commentId = DateTime.now().millisecondsSinceEpoch.toString();
    final userName = currentUser.fullName ?? 'User';
    final userAvatar = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    // Optimistic update: Add comment to UI immediately
    final optimisticComment = {
      'id': commentId,
      'name': userName,
      'avatar': userAvatar,
      'content': commentText,
      'time': 'now',
      'userId': currentUserId,
    };

    setState(() {
      _comments.insert(0, optimisticComment);
      _isSubmittingComment = true;
    });

    _commentController.clear();

    // Save to Firestore with retry logic
    const maxRetries = 3;
    int retryCount = 0;
    bool success = false;

    while (retryCount < maxRetries && !success) {
      try {
        final batch = _firestore.batch();

        // Add comment document
        final commentRef = _firestore
            .collection('posts')
            .doc(widget.post.id)
            .collection('comments')
            .doc(commentId);

        batch.set(commentRef, {
          'userId': currentUserId,
          'userName': userName,
          'userAvatar': userAvatar,
          'content': commentText,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update post commentsCount
        final postRef = _firestore.collection('posts').doc(widget.post.id);
        batch.update(postRef, {
          'commentsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        
        success = true;
        debugPrint('Comment added successfully');

        // Refresh comments to get server timestamp
        await _loadComments();
      } catch (e) {
        retryCount++;
        final isTransient = _isTransientError(e);

        if (isTransient && retryCount < maxRetries) {
          final delaySeconds = retryCount;
          debugPrint('Transient error adding comment (attempt $retryCount/$maxRetries), retrying in ${delaySeconds}s...');
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          // Revert optimistic update on failure
          if (mounted) {
            setState(() {
              _comments.removeWhere((c) => c['id'] == commentId);
              _isSubmittingComment = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Unable to add comment. Please check your connection.'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          debugPrint('Error adding comment: $e');
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1F295B).withOpacity(0.85),
                const Color(0xFF283B89).withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: const Color(0xFF6B8FAE).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              Divider(color: AppColors.textSecondary.withOpacity(0.3)),
              
              // Comments list
              Expanded(
                child: _isLoadingComments
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        comment['avatar'] ?? 'U',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                comment['name'] ?? 'User',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                comment['time'] ?? 'now',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment['content'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              
              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.textSecondary.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        final currentUser = authService.userModel;
                        return CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            currentUser?.fullName?.isNotEmpty == true ? currentUser!.fullName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: const Color(0xFF6B8FAE).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: const Color(0xFF6B8FAE).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: AppColors.primaryLight,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                                          const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSubmittingComment ? null : _addComment,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isSubmittingComment
                                ? AppColors.primary.withOpacity(0.5)
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _isSubmittingComment
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                                  ),
                                )
                              : Icon(
                                  Icons.send,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// Share Modal
class ShareModal extends StatelessWidget {
  final PostModel post;

  const ShareModal({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1F295B).withOpacity(0.85),
                const Color(0xFF283B89).withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: const Color(0xFF6B8FAE).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Text(
                'Share Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Share options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.copy,
                    label: 'Copy Link',
                    onTap: () {
                      Navigator.pop(context);
                      // Copy post content to clipboard
                      final shareText = 'Check out this post by ${post.userName}: "${post.content}"';
                      Share.share(shareText);
                    },
                  ),
                  _ShareOption(
                    icon: Icons.message,
                    label: 'Message',
                    onTap: () {
                      Navigator.pop(context);
                      final shareText = 'Check out this post by ${post.userName}: "${post.content}"';
                      Share.share(shareText, subject: 'Shared from Vynco');
                    },
                  ),
                  _ShareOption(
                    icon: Icons.email,
                    label: 'Email',
                    onTap: () {
                      Navigator.pop(context);
                      final shareText = 'Check out this post by ${post.userName}: "${post.content}"';
                      Share.share(shareText, subject: 'Shared from Vynco');
                    },
                  ),
                  _ShareOption(
                    icon: Icons.more_horiz,
                    label: 'More',
                    onTap: () {
                      Navigator.pop(context);
                      final shareText = 'Check out this post by ${post.userName}: "${post.content}"';
                      Share.share(shareText, subject: 'Shared from Vynco');
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Retryable Network Image Widget with automatic retry logic and optimization
// Widget that adapts container size to image aspect ratio
class _AdaptiveImageContainer extends StatefulWidget {
  final String imageUrl;

  const _AdaptiveImageContainer({
    required this.imageUrl,
  });

  @override
  State<_AdaptiveImageContainer> createState() => _AdaptiveImageContainerState();
}

class _AdaptiveImageContainerState extends State<_AdaptiveImageContainer> {
  double? _aspectRatio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    try {
      final imageProvider = NetworkImage(widget.imageUrl);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final completer = Completer<ImageInfo>();
      
      final listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(info);
        }
      });
      
      imageStream.addListener(listener);
      
      final imageInfo = await completer.future;
      final image = imageInfo.image;
      
      imageStream.removeListener(listener);
      
      if (mounted) {
        setState(() {
          _aspectRatio = image.width / image.height;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If we can't get dimensions, use a default aspect ratio (16:9)
      if (mounted) {
        setState(() {
          _aspectRatio = 16 / 9;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _aspectRatio == null) {
      return Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.width / (16 / 9), // Default 16:9 while loading
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 20)),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 20)),
        child: AspectRatio(
          aspectRatio: _aspectRatio!,
          child: _RetryableNetworkImage(
            imageUrl: widget.imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _RetryableNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _RetryableNetworkImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<_RetryableNetworkImage> createState() => _RetryableNetworkImageState();
}

class _RetryableNetworkImageState extends State<_RetryableNetworkImage> {
  int _attemptKey = 0;
  static const int _maxRetries = 2; // Reduced from 3 to 2
  bool _hasError = false;
  bool _isRetrying = false;
  bool _hasScheduledRetry = false;

  @override
  void initState() {
    super.initState();
    // Skip precache - let image load directly for faster display
  }

  void _retry() {
    setState(() {
      _attemptKey = 0;
      _hasError = false;
      _isRetrying = false;
      _hasScheduledRetry = false;
    });
  }

  void _scheduleRetry() {
    if (_hasScheduledRetry || _attemptKey >= _maxRetries) {
      if (_attemptKey >= _maxRetries && mounted) {
        setState(() {
          _hasError = true;
          _isRetrying = false;
        });
      }
      return;
    }

    _hasScheduledRetry = true;
    final currentAttempt = _attemptKey + 1;
    final delaySeconds = 0.5; // Reduced from currentAttempt to 0.5s for faster retry
    
    debugPrint('RetryableNetworkImage: Failed to load ${widget.imageUrl} (attempt $currentAttempt/$_maxRetries), retrying in ${delaySeconds}s...');
    
    if (mounted) {
      setState(() {
        _isRetrying = true;
      });
    }
    
    Future.delayed(Duration(milliseconds: (delaySeconds * 1000).toInt()), () {
      if (mounted) {
        setState(() {
          _attemptKey = currentAttempt;
          _isRetrying = false;
          _hasScheduledRetry = false;
        });
      }
    });
  }

  Widget _buildLoadingContainer() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.grey700.withOpacity(0.6),
            AppColors.grey50.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildErrorContainer({String? retryText}) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.grey700.withOpacity(0.6),
            AppColors.grey50.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 60,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 12),
            Text(
              retryText ?? 'Failed to load image',
              style: TextStyle(
                color: AppColors.grey500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_attemptKey >= _maxRetries) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _retry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show error state if all retries exhausted
    if (_hasError && _attemptKey >= _maxRetries) {
      return _buildErrorContainer();
    }

    // If we're retrying, show loading indicator
    if (_isRetrying || (_attemptKey > 0 && _attemptKey < _maxRetries)) {
      return _buildLoadingContainer();
    }

      // Helper function to safely convert to int for caching
      int? _safeToInt(double? value) {
        if (value == null) return null;
        if (!value.isFinite || value.isNaN || value <= 0) return null;
        try {
          return value.toInt();
        } catch (e) {
          return null;
        }
      }
      
      // Use Image.network directly with timeout - faster than precaching
      return Image.network(
        widget.imageUrl,
        key: ValueKey('${widget.imageUrl}_$_attemptKey'),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: _safeToInt(widget.width),
        cacheHeight: _safeToInt(widget.height),
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Image loaded successfully
            if (_attemptKey > 0 && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _attemptKey = 0;
                    _hasError = false;
                    _isRetrying = false;
                    _hasScheduledRetry = false;
                  });
                }
              });
            }
            return child;
          }
          // Show loading indicator
          return _buildLoadingContainer();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image load error for ${widget.imageUrl}: $error');
          
          // Schedule retry if we haven't exceeded max retries
          if (!_hasScheduledRetry && _attemptKey < _maxRetries) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _scheduleRetry();
              }
            });
          } else if (_attemptKey >= _maxRetries) {
            // All retries exhausted
            if (mounted) {
              setState(() {
                _hasError = true;
                _isRetrying = false;
              });
            }
            return _buildErrorContainer();
          }
          
          // Show loading indicator while retrying
          if (_isRetrying || (_attemptKey > 0 && _attemptKey < _maxRetries)) {
            return _buildLoadingContainer();
          }
          
          return _buildErrorContainer();
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }
}
