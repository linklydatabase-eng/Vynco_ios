import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/post_service.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/profile/profile_edit_screen.dart';
import 'screens/people/people_search_screen.dart';
import 'screens/network/network_screen.dart';
import 'screens/connections/connections_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/connections/qr_scanner_screen.dart';
import 'widgets/main_navigation_wrapper.dart';
import 'screens/people_around_screen.dart';
import 'screens/posts/posts_screen.dart';
import 'screens/status/status_screen.dart';
import 'screens/groups/groups_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/digital_card/digital_card_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'constants/app_theme.dart';
import 'screens/legal/terms_of_service_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      debugPrint('🔵 Initializing Firebase...');
      // Initialize Firebase only if not already initialized
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Verify Firebase is actually initialized
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase initialization completed but no apps found');
      }
      
      debugPrint('✅ Firebase app initialized: ${Firebase.apps.first.name}');
      
      // Initialize Firebase Crashlytics
      try {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        
        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        debugPrint('✅ Firebase Crashlytics initialized');
      } catch (e) {
        debugPrint('⚠️ Firebase Crashlytics initialization failed: $e');
        // Continue even if Crashlytics fails
      }
      
      // Test Firebase Auth availability
      try {
        final auth = FirebaseAuth.instance;
        debugPrint('✅ Firebase Auth instance available');
      } catch (e) {
        debugPrint('⚠️ Firebase Auth test failed: $e');
        throw Exception('Firebase Auth not available: $e');
      }
      
      firebaseInitialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } else {
      // Firebase is already initialized
      firebaseInitialized = true;
      debugPrint('✅ Firebase already initialized (${Firebase.apps.length} app(s))');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    debugPrint('❌ Continuing without Firebase authentication...');
    firebaseInitialized = false;
  }
  
  runApp(VyncoApp(firebaseInitialized: firebaseInitialized));
}

class VyncoApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const VyncoApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(firebaseInitialized: firebaseInitialized)),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => PostService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: _RouterWrapper(),
    );
  }
}

class _RouterWrapper extends StatefulWidget {
  @override
  State<_RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<_RouterWrapper> {
  late final GoRouter _router;
  
  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _router = _createRouter(authService);
    
    // Listen to auth changes and refresh router
    authService.addListener(_onAuthChanged);
  }
  
  void _onAuthChanged() {
    _router.refresh();
  }
  
  @override
  void dispose() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.removeListener(_onAuthChanged);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp.router(
          title: 'Vynco',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}

GoRouter _createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final bool isAuthenticated = authService.isAuthenticated;
      final bool isLoading = authService.isLoading;
      final String currentPath = state.uri.toString();

      // Don't redirect if we're on splash screen or if loading
      if (currentPath == '/splash' || isLoading) {
        return null;
      }

      // List of routes accessible to everyone (authenticated and unauthenticated)
      final bool isPublicRoute =
          currentPath == '/terms' ||
          currentPath == '/privacy';

      // List of routes accessible to unauthenticated users only
      final bool isAuthRoute =
          currentPath == '/login' ||
          currentPath == '/register' ||
          currentPath == '/forgot-password' ||
          currentPath == '/onboarding';

      // Always allow public routes
      if (isPublicRoute) {
        return null;
      }

      // If not authenticated
      if (!isAuthenticated) {
        // If trying to access a protected route, redirect to onboarding
        if (!isAuthRoute) {
          return '/onboarding';
        }
        // If already on an auth route, allow it
        return null;
      }
      // If authenticated
      else {
        // Check if username setup is needed (for Google sign-in users)
        final bool needsUsernameSetup = authService.needsUsernameSetup;
        final bool isProfileSetupRoute = currentPath == '/profile-setup';
        
        // If username setup is needed and not on profile setup page, redirect there
        if (needsUsernameSetup && !isProfileSetupRoute) {
          return '/profile-setup';
        }
        
        // If username is set up and on profile setup page, redirect to home
        if (!needsUsernameSetup && isProfileSetupRoute) {
          return '/home';
        }
        
        // If authenticated and on an auth route, redirect to home
        if (isAuthRoute) {
          return '/home';
        }
        // If authenticated and on a protected route, allow it
        return null;
      }
    },
    routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/profile-edit',
      builder: (context, state) {
        // Check if coming from Settings (preserve Settings tab in bottom nav)
        final fromSettings = state.uri.queryParameters['from'] == 'settings';
        final initialIndex = fromSettings ? 4 : 3; // 4 = Settings tab, 3 = Profile tab
        return ProfileEditWrapper(
          initialIndex: initialIndex,
        );
      },
    ),
    GoRoute(
      path: '/people-search',
      builder: (context, state) => const PeopleSearchScreen(),
    ),
    GoRoute(
      path: '/network',
      builder: (context, state) => const NetworkScreen(),
    ),
    GoRoute(
      path: '/connections',
      pageBuilder: (context, state) {
        final groupName = state.uri.queryParameters['group'];
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: ConnectionsScreen(groupName: groupName),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubicEmphasized,
            );
            final dissolve = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
            final scale = Tween<double>(begin: 1.04, end: 1.0).animate(curvedAnimation);

            return AnimatedBuilder(
              animation: dissolve,
              builder: (context, _) {
                return Opacity(
                  opacity: dissolve.value,
                  child: Transform.scale(
                    scale: scale.value,
                    alignment: Alignment.center,
                    child: child,
                  ),
                );
              },
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsWrapper(),
    ),
    GoRoute(
      path: '/qr-scanner',
      builder: (context, state) => const QRScannerScreen(),
    ),
    GoRoute(
      path: '/people-around',
      builder: (context, state) => const PeopleAroundScreen(),
    ),
    GoRoute(
      path: '/posts',
      builder: (context, state) => const PostsScreen(),
    ),
    GoRoute(
      path: '/status',
      builder: (context, state) => const StatusScreen(),
    ),
    GoRoute(
      path: '/groups',
      builder: (context, state) => const GroupsScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/digital-card',
      builder: (context, state) => const DigitalCardScreen(),
    ),
  ],
  );
}