import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _animationCompleted = false;
  bool _hasNavigated = false;
  
  // Icon animations
  late Animation<double> _iconFadeAnimation;
  late Animation<double> _iconScaleAnimation;
  
  // Title animations
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _titleScaleAnimation;
  
  // Subtitle animations
  late Animation<double> _subtitleFadeAnimation;
  late Animation<double> _subtitleScaleAnimation;
  
  // Loading indicator animation
  late Animation<double> _loadingFadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: initState called');
    _setupAnimations();
    _checkAuthStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Icon: fades and zooms in first (0.0 - 0.4)
    _iconFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));
    
    _iconScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    // Title: fades and zooms in second (0.3 - 0.7)
    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    ));
    
    _titleScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));

    // Subtitle: fades and zooms in third (0.5 - 0.9)
    _subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    ));
    
    _subtitleScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
    ));

    // Loading indicator: fades in last (0.7 - 1.0)
    _loadingFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationCompleted = true;
        });
      }
    });

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    debugPrint('SplashScreen: Starting auth check');
    
    // Defer navigation until after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check auth immediately
      try {
        if (!mounted || _hasNavigated) return;
        debugPrint('SplashScreen: Checking auth service');
        final authService = Provider.of<AuthService>(context, listen: false);
        
        if (authService.isAuthenticated) {
          debugPrint('SplashScreen: User is authenticated, going to home');
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            context.go('/home');
          }
        } else {
          debugPrint('SplashScreen: User not authenticated, going to onboarding');
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            context.go('/onboarding');
          }
        }
      } catch (e) {
        debugPrint('Auth check error: $e');
        // If there's an error, go to onboarding anyway
        if (mounted && !_hasNavigated) {
          debugPrint('SplashScreen: Error occurred, going to onboarding');
          _hasNavigated = true;
          context.go('/onboarding');
        }
      }
      
      // Fallback timeout - navigate after max 3 seconds if still on splash
      Future.delayed(const Duration(seconds: 3)).then((_) {
        if (mounted && !_hasNavigated) {
          debugPrint('SplashScreen: Timeout fallback - navigating...');
          final authService = Provider.of<AuthService>(context, listen: false);
          _hasNavigated = true;
          if (authService.isAuthenticated) {
            context.go('/home');
          } else {
            context.go('/onboarding');
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF002171)],
          ),
        ),
        child: Center(
          child: _animationCompleted
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo container - static after animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.link,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // App name - static after animation
                    const Text(
                      'Vynco',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Subtitle - static after animation
                    const Text(
                      'Digital Business Cards',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Loading indicator - continuously animated
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      strokeWidth: 2,
                    ),
                  ],
                )
              : AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo container - animates first
                        FadeTransition(
                          opacity: _iconFadeAnimation,
                          child: Transform.scale(
                            scale: _iconScaleAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.link,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // App name - animates second
                        FadeTransition(
                          opacity: _titleFadeAnimation,
                          child: Transform.scale(
                            scale: _titleScaleAnimation.value,
                            child: const Text(
                              'Vynco',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Subtitle - animates third
                        FadeTransition(
                          opacity: _subtitleFadeAnimation,
                          child: Transform.scale(
                            scale: _subtitleScaleAnimation.value,
                            child: const Text(
                              'Digital Business Cards',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.white,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        // Loading indicator - animates last
                        FadeTransition(
                          opacity: _loadingFadeAnimation,
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
