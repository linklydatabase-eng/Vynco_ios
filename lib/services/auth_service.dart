import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/digital_card_themes.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  FirebaseFirestore? _firestore;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isFirebaseAvailable = false;
  
  // Performance optimization: Cache and debounce
  Timer? _debounceTimer;
  DateTime? _lastUserModelLoad;
  static const _userModelCacheDuration = Duration(minutes: 5);
  
  // Check if username setup is needed
  bool get needsUsernameSetup {
    if (_userModel == null || _user == null) return false;
    final username = _userModel!.username;
    return username.isEmpty;
  }

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isFirebaseAvailable => _isFirebaseAvailable;
  String get digitalCardTheme => _userModel?.digitalCardTheme ?? DigitalCardThemes.defaultThemeId;
  bool get isAuthenticated => _user != null || (_userModel != null && !_isFirebaseAvailable);

  AuthService({bool firebaseInitialized = true}) {
    if (firebaseInitialized) {
      try {
        // Verify Firebase is actually initialized
        if (Firebase.apps.isEmpty) {
          debugPrint('⚠️ Firebase apps list is empty, Firebase may not be initialized');
          _isFirebaseAvailable = false;
          _initializeMockUser();
          return;
        }
        
        // Try to initialize Firebase services
        try {
          _auth = FirebaseAuth.instance;
          _firestore = FirebaseFirestore.instance;
        } catch (e) {
          debugPrint('⚠️ Error accessing Firebase services: $e');
          // Check if Firebase apps exist - if they do, Firebase is available
          if (Firebase.apps.isNotEmpty) {
            debugPrint('✅ Firebase apps exist (${Firebase.apps.length}), retrying service initialization...');
            try {
              _auth = FirebaseAuth.instance;
              _firestore = FirebaseFirestore.instance;
            } catch (e2) {
              debugPrint('❌ Failed to initialize Firebase services after retry: $e2');
              _isFirebaseAvailable = false;
              _initializeMockUser();
              return;
            }
          } else {
            _isFirebaseAvailable = false;
            _initializeMockUser();
            return;
          }
        }
        
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          // serverClientId is required for getting ID token for Firebase Auth
          serverClientId: '651351206557-js9ir0prhqr6qct7u24i8k5hgtpgfps1.apps.googleusercontent.com',
        );
        debugPrint('✅ GoogleSignIn initialized with serverClientId');
        _isFirebaseAvailable = true;
        _auth!.authStateChanges().listen(_onAuthStateChanged);
        debugPrint('✅ AuthService initialized with REAL Firebase authentication');
        debugPrint('✅ Google Sign-In configured with scopes: email, profile');
        debugPrint('✅ Users will be created in Firebase Console');
        debugPrint('✅ Only registered users can sign in');
      } catch (e, stackTrace) {
        debugPrint('❌ AuthService initialization error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        // If Firebase apps exist, Firebase is actually available
        if (Firebase.apps.isNotEmpty) {
          debugPrint('⚠️ Exception occurred but Firebase apps exist (${Firebase.apps.length}), marking as available');
          try {
            _auth = FirebaseAuth.instance;
            _firestore = FirebaseFirestore.instance;
            _googleSignIn = GoogleSignIn(
              scopes: ['email', 'profile'],
              serverClientId: '651351206557-js9ir0prhqr6qct7u24i8k5hgtpgfps1.apps.googleusercontent.com',
            );
            _isFirebaseAvailable = true;
            _auth!.authStateChanges().listen(_onAuthStateChanged);
            debugPrint('✅ AuthService recovered and initialized with Firebase');
          } catch (e2) {
            debugPrint('❌ Failed to recover Firebase services: $e2');
            _isFirebaseAvailable = false;
            _initializeMockUser();
          }
        } else {
          _isFirebaseAvailable = false;
          _initializeMockUser();
        }
      }
    } else {
      debugPrint('❌ AuthService initialized without Firebase (disabled)');
      _isFirebaseAvailable = false;
      _initializeMockUser();
    }
  }

  void _initializeMockUser() {
    // Don't auto-authenticate - let user go through login flow
    _user = null;
    _userModel = null;
    debugPrint('AuthService: Ready for user authentication');
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      // Load user model asynchronously without blocking
      _loadUserModelDebounced();
    } else {
      _userModel = null;
      _lastUserModelLoad = null;
    }
    // Notify immediately so navigation can proceed
    // User model will load in background
    notifyListeners();
  }

  void _loadUserModelDebounced() {
    // Cancel any pending load
    _debounceTimer?.cancel();
    
    // Load immediately without debounce to avoid blocking navigation
    // Use unawaited to make it non-blocking
    _loadUserModel();
  }

  Future<void> _loadUserModel() async {
    if (_user == null || _firestore == null) return;
    
    // Check cache first
    if (_lastUserModelLoad != null && 
        DateTime.now().difference(_lastUserModelLoad!) < _userModelCacheDuration) {
      debugPrint('AuthService: Using cached user model');
      return;
    }
    
    try {
      // Add timeout to prevent hanging on network issues
      final doc = await _firestore!.collection('users').doc(_user!.uid)
          .get()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('AuthService: User model load timed out');
        throw TimeoutException('User model load timed out');
      });
      
      if (doc.exists) {
        final data = doc.data()!;
        _userModel = UserModel.fromMap(data);
        _lastUserModelLoad = DateTime.now();
        notifyListeners();
      }
    } on TimeoutException {
      debugPrint('AuthService: User model load timed out, continuing without it');
      // Don't throw - allow app to continue without user model
    } catch (e) {
      debugPrint('Error loading user model: $e');
      // Don't throw - allow app to continue without user model
    }
  }


  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Avoid unnecessary updates
    _isLoading = loading;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    // Re-check Firebase availability - if apps exist, Firebase is available
    if (Firebase.apps.isNotEmpty && !_isFirebaseAvailable) {
      debugPrint('⚠️ Firebase apps exist but flag was false, updating availability...');
      try {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _isFirebaseAvailable = true;
        debugPrint('✅ Firebase availability updated to true');
      } catch (e) {
        debugPrint('❌ Failed to reinitialize Firebase: $e');
      }
    }
    
    // Double-check Firebase availability before proceeding
    if (!_isFirebaseAvailable || Firebase.apps.isEmpty) {
      debugPrint('❌ Firebase not available - apps: ${Firebase.apps.length}, _isFirebaseAvailable: $_isFirebaseAvailable');
      throw Exception('Firebase is not available. Please restart the app and check your internet connection.');
    }
    
    try {
      _setLoading(true);
      
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }
      
      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }
      
      // Retry logic for network errors
      const maxRetries = 3;
      int retryCount = 0;
      UserCredential? credential;
      
      while (retryCount < maxRetries) {
        try {
          credential = await _auth!.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          break; // Success, exit retry loop
        } catch (e) {
          final errorStr = e.toString();
          final isNetworkError = errorStr.contains('network-request-failed') ||
                                 errorStr.contains('network-error') ||
                                 errorStr.contains('Unable to resolve host') ||
                                 errorStr.contains('timeout') ||
                                 errorStr.contains('UNAVAILABLE') ||
                                 (e is FirebaseAuthException && 
                                  (e.code == 'network-request-failed' || 
                                   e.code == 'network-error'));
          
          if (isNetworkError && retryCount < maxRetries - 1) {
            retryCount++;
            debugPrint('Network error detected. Retrying sign in (attempt $retryCount/$maxRetries)...');
            await Future.delayed(Duration(seconds: retryCount));
            continue;
          }
          rethrow; // Re-throw if not network error or max retries reached
        }
      }
      
      if (credential == null) {
        throw Exception('Sign in failed after retries');
      }
      
      // Ensure user is set immediately (auth state listener will also update it)
      if (credential.user != null) {
        _user = credential.user;
        notifyListeners();
      }
      
      return credential;
    } catch (e) {
      debugPrint('Sign in error: $e');
      if (e.toString().contains('user-not-found')) {
        throw Exception('No account found with this email address. Please sign up first.');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Please enter a valid email address');
      } else if (e.toString().contains('user-disabled')) {
        throw Exception('This account has been disabled. Please contact support.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many failed attempts. Please try again later.');
      } else if (e.toString().contains('network-request-failed') || 
                 e.toString().contains('Unable to resolve host')) {
        throw Exception('Network error. Please check your internet connection and DNS settings. If using an emulator, try restarting it or using a physical device.');
      } else {
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    if (!_isFirebaseAvailable) {
      return false; // In mock mode, assume username doesn't exist
    }
    
    try {
      // Check if username exists in Firestore users collection
      final querySnapshot = await _firestore!
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking username existence: $e');
      return false; // If there's an error, allow the signup to proceed
    }
  }

  Future<bool> checkEmailExists(String email) async {
    if (!_isFirebaseAvailable) {
      return false; // In mock mode, assume email doesn't exist
    }
    
    try {
      // Check if email exists in Firestore users collection
      final querySnapshot = await _firestore!
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking email existence: $e');
      return false; // If there's an error, allow the signup to proceed
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password, String fullName, {String? username, String? phoneNumber, String? company, String? accountType}) async {
    // Re-check Firebase availability - if apps exist, Firebase is available
    if (Firebase.apps.isNotEmpty && !_isFirebaseAvailable) {
      debugPrint('⚠️ Firebase apps exist but flag was false, updating availability...');
      try {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _isFirebaseAvailable = true;
        debugPrint('✅ Firebase availability updated to true');
      } catch (e) {
        debugPrint('❌ Failed to reinitialize Firebase: $e');
      }
    }
    
    // Double-check Firebase availability before proceeding
    if (!_isFirebaseAvailable || Firebase.apps.isEmpty) {
      debugPrint('❌ Firebase not available - apps: ${Firebase.apps.length}, _isFirebaseAvailable: $_isFirebaseAvailable');
      throw Exception('Firebase is not available. Please restart the app and check your internet connection.');
    }
    
    try {
      _setLoading(true);
      
      if (email.isEmpty || password.isEmpty || fullName.isEmpty || username == null || username.isEmpty) {
        throw Exception('All fields are required');
      }
      
      if (username.length < 3) {
        throw Exception('Username must be at least 3 characters');
      }
      
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        throw Exception('Username can only contain letters, numbers, and underscores');
      }
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        await credential.user!.updateDisplayName(fullName.trim());
        
        await _firestore!.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email.trim(),
          'fullName': fullName.trim(),
          'username': username.trim(),
          'phoneNumber': phoneNumber?.trim() ?? '',
          'company': company?.trim() ?? '',
          'position': '',
          'bio': '',
          'accountType': accountType ?? 'Public',
          'phoneNumberPrivacy': 'connections_only', // Default privacy setting
          'allowedPhoneViewers': [], // Empty list by default
          'socialLinks': {},
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
      }
      
      return credential;
    } catch (e) {
      debugPrint('Sign up error: $e');
      if (e.toString().contains('email-already-in-use')) {
        throw Exception('An account with this email already exists');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('Password is too weak. Please choose a stronger password');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Please enter a valid email address');
      } else if (e.toString().contains('PigeonUserDetails')) {
        throw Exception('Authentication service error. Please try again');
      } else {
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> signInWithUsernameOrEmail(String usernameOrEmail, String password) async {
    // Re-check Firebase availability - if apps exist, Firebase is available
    if (Firebase.apps.isNotEmpty && !_isFirebaseAvailable) {
      debugPrint('⚠️ Firebase apps exist but flag was false, updating availability...');
      try {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _isFirebaseAvailable = true;
        debugPrint('✅ Firebase availability updated to true');
      } catch (e) {
        debugPrint('❌ Failed to reinitialize Firebase: $e');
      }
    }
    
    // Double-check Firebase availability before proceeding
    if (!_isFirebaseAvailable || Firebase.apps.isEmpty) {
      debugPrint('❌ Firebase not available - apps: ${Firebase.apps.length}, _isFirebaseAvailable: $_isFirebaseAvailable');
      throw Exception('Firebase is not available. Please restart the app and check your internet connection.');
    }
    
    try {
      _setLoading(true);
      
      if (usernameOrEmail.isEmpty || password.isEmpty) {
        throw Exception('Username/Email and password are required');
      }

      String email = usernameOrEmail.trim();
      
      // Check if it's a username (not an email format)
      if (!email.contains('@')) {
        // It's a username, find the corresponding email
        final userQuery = await _firestore!.collection('users')
            .where('username', isEqualTo: email)
            .limit(1)
            .get();
        
        if (userQuery.docs.isEmpty) {
          throw Exception('No account found with this username. Please sign up first.');
        }
        
        email = userQuery.docs.first.data()['email'] as String;
      }

      // Retry logic for network errors
      const maxRetries = 3;
      int retryCount = 0;
      UserCredential? credential;
      
      while (retryCount < maxRetries) {
        try {
          credential = await _auth!.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          break; // Success, exit retry loop
        } catch (e) {
          final errorStr = e.toString();
          final isNetworkError = errorStr.contains('network-request-failed') ||
                                 errorStr.contains('network-error') ||
                                 errorStr.contains('Unable to resolve host') ||
                                 errorStr.contains('timeout') ||
                                 errorStr.contains('UNAVAILABLE') ||
                                 (e is FirebaseAuthException && 
                                  (e.code == 'network-request-failed' || 
                                   e.code == 'network-error'));
          
          if (isNetworkError && retryCount < maxRetries - 1) {
            retryCount++;
            debugPrint('Network error detected. Retrying sign in (attempt $retryCount/$maxRetries)...');
            await Future.delayed(Duration(seconds: retryCount));
            continue;
          }
          rethrow; // Re-throw if not network error or max retries reached
        }
      }
      
      if (credential == null) {
        throw Exception('Sign in failed after retries');
      }
      
      // Ensure user is set immediately (auth state listener will also update it)
      if (credential.user != null) {
        _user = credential.user;
        notifyListeners();
      }
      
      return credential;
    } catch (e) {
      debugPrint('Sign in error: $e');
      if (e.toString().contains('user-not-found')) {
        throw Exception('No account found with this username/email. Please sign up first.');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many failed attempts. Please try again later.');
      } else if (e.toString().contains('user-disabled')) {
        throw Exception('This account has been disabled. Please contact support.');
      } else if (e.toString().contains('network-request-failed') || 
                 e.toString().contains('Unable to resolve host')) {
        throw Exception('Network error. Please check your internet connection and DNS settings. If using an emulator, try restarting it or using a physical device.');
      } else {
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    // Re-check Firebase availability - if apps exist, Firebase is available
    if (Firebase.apps.isNotEmpty && !_isFirebaseAvailable) {
      debugPrint('⚠️ Firebase apps exist but flag was false, updating availability...');
      try {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _googleSignIn ??= GoogleSignIn(
            scopes: ['email', 'profile'],
            serverClientId: '651351206557-js9ir0prhqr6qct7u24i8k5hgtpgfps1.apps.googleusercontent.com',
          );
        _isFirebaseAvailable = true;
        debugPrint('✅ Firebase availability updated to true');
      } catch (e) {
        debugPrint('❌ Failed to reinitialize Firebase: $e');
      }
    }
    
    // Double-check Firebase availability before proceeding
    if (!_isFirebaseAvailable || Firebase.apps.isEmpty) {
      debugPrint('❌ Firebase not available - apps: ${Firebase.apps.length}, _isFirebaseAvailable: $_isFirebaseAvailable');
      throw Exception('Firebase is not available. Please restart the app and check your internet connection.');
    }
    
    try {
      _setLoading(true);
      debugPrint('🔵 Starting Google Sign-In process...');
      
      // Trigger the authentication flow
      debugPrint('🔵 Requesting Google Sign-In account...');
      debugPrint('🔵 GoogleSignIn configuration - serverClientId: ${_googleSignIn?.serverClientId ?? "not set"}');
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn!.signIn();
      } catch (signInError) {
        debugPrint('❌ Error during GoogleSignIn.signIn(): $signInError');
        debugPrint('❌ Error type: ${signInError.runtimeType}');
        rethrow;
      }
      if (googleUser == null) {
        debugPrint('⚠️ Google sign-in was cancelled by user');
        return null;
      }
      
      debugPrint('✅ Google account selected: ${googleUser.email}');
      
      // Obtain the auth details from the request
      debugPrint('🔵 Obtaining authentication tokens from Google...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Check if we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Missing authentication tokens - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}');
        throw Exception('Failed to get authentication tokens from Google. Please ensure Google Sign-In is properly configured.');
      }
      
      debugPrint('✅ Authentication tokens obtained successfully');
      
      // Create a new credential
      debugPrint('🔵 Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );
      
      // Sign in to Firebase with the Google credential
      debugPrint('🔵 Signing in to Firebase with Google credential...');
      final userCredential = await _auth!.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        debugPrint('❌ Firebase sign-in succeeded but user is null');
        throw Exception('Authentication succeeded but user data is missing. Please try again.');
      }
      
      debugPrint('✅ Firebase authentication successful for: ${userCredential.user?.email}');
      
      // Create or update user document in Firestore
      debugPrint('🔵 Updating user document in Firestore...');
      final userDocRef = _firestore!.collection('users').doc(userCredential.user!.uid);
      final userDoc = await userDocRef.get();
      
      // Only update if document doesn't exist or doesn't have username
      if (!userDoc.exists || userDoc.data()?['username'] == null || (userDoc.data()?['username'] as String).isEmpty) {
        await userDocRef.set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email ?? '',
          'fullName': userCredential.user!.displayName ?? 'Google User',
          'profileImageUrl': userCredential.user!.photoURL,
          'phoneNumberPrivacy': 'connections_only', // Default privacy setting
          'allowedPhoneViewers': [], // Empty list by default
          'socialLinks': {},
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        }, SetOptions(merge: true));
        debugPrint('✅ User document created/updated in Firestore');
      } else {
        // Update only non-username fields if username already exists
        await userDocRef.update({
          'email': userCredential.user!.email ?? '',
          'fullName': userCredential.user!.displayName ?? 'Google User',
          'profileImageUrl': userCredential.user!.photoURL,
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
        debugPrint('✅ User document updated in Firestore');
      }
      
      // Reload user model to check username status
      debugPrint('🔵 Reloading user model...');
      await _loadUserModel();
      
      debugPrint('✅ Google sign in successful for: ${userCredential.user?.email}');
      return userCredential;
    } catch (e, stackTrace) {
      debugPrint('❌ Google sign in error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Provide more specific error messages based on error type
      final errorString = e.toString().toLowerCase();
      final errorMessage = e.toString();
      
      // Check for specific error codes
      if (errorString.contains('sign_in_failed') || errorString.contains('sign_in_canceled')) {
        debugPrint('❌ Google Sign-In failed - likely configuration issue');
        // Check if it's a developer error (SHA certificate issue)
        if (errorString.contains('10:') || errorString.contains('developer_error') || errorString.contains('12500')) {
          throw Exception('Google Sign-In configuration error: SHA certificate fingerprint mismatch. Please ensure the app SHA-1 certificate is added to Firebase Console for package name com.vynco.app.');
        }
        throw Exception('Google sign-in failed. Please ensure the app is properly configured in Firebase Console.');
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        debugPrint('❌ Network error during Google Sign-In');
        throw Exception('Network error. Please check your internet connection and try again.');
      } else if (errorString.contains('pigeonuserdetails') || errorString.contains('platform')) {
        debugPrint('❌ Platform/authentication service error');
        throw Exception('Authentication service error. Please try again.');
      } else if (errorString.contains('10:') || errorString.contains('developer_error') || errorString.contains('12500')) {
        debugPrint('❌ Developer error - likely missing OAuth client or SHA certificate');
        throw Exception('Google Sign-In configuration error: SHA certificate fingerprint mismatch. Please ensure the app SHA-1 certificate is added to Firebase Console for package name com.vynco.app.');
      } else if (errorString.contains('invalid_credential') || errorString.contains('credential')) {
        debugPrint('❌ Invalid credential error');
        throw Exception('Authentication failed. Please try signing in again.');
      } else {
        // Preserve original error for debugging but provide user-friendly message
        debugPrint('❌ Unexpected error: $e');
        // Extract the actual error message if it's wrapped
        if (errorMessage.contains('Exception: ')) {
          final actualError = errorMessage.split('Exception: ').last.trim();
          throw Exception(actualError);
        }
        rethrow;
      }
    } finally {
      _setLoading(false);
      debugPrint('🔵 Google Sign-In process completed');
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      debugPrint('Signing out');
      
      if (_isFirebaseAvailable) {
        try {
          // Sign out from Firebase Auth
          await _auth!.signOut();
          debugPrint('✅ Firebase Auth sign out successful');
        } catch (e) {
          debugPrint('⚠️ Firebase Auth sign out error: $e');
          // Continue with sign out even if Firebase fails
        }
        
        try {
          // Sign out from Google Sign-In
          await _googleSignIn!.signOut();
          debugPrint('✅ Google Sign-In sign out successful');
        } catch (e) {
          debugPrint('⚠️ Google Sign-In sign out error: $e');
          // Continue with sign out even if Google fails
        }
      } else {
        debugPrint('✅ Local authentication sign out');
      }
      
      // Clear user data (always do this)
      _user = null;
      _userModel = null;
      
      // Notify listeners
      notifyListeners();
      
      debugPrint('✅ Sign out completed successfully');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      // Even if there's an error, clear the user data
      _user = null;
      _userModel = null;
      notifyListeners();
    } finally {
      // Always reset loading state
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    // Re-check Firebase availability - if apps exist, Firebase is available
    if (Firebase.apps.isNotEmpty && !_isFirebaseAvailable) {
      debugPrint('⚠️ Firebase apps exist but flag was false, updating availability...');
      try {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _isFirebaseAvailable = true;
        debugPrint('✅ Firebase availability updated to true');
      } catch (e) {
        debugPrint('❌ Failed to reinitialize Firebase: $e');
      }
    }
    
    // Double-check Firebase availability before proceeding
    if (!_isFirebaseAvailable || Firebase.apps.isEmpty) {
      debugPrint('❌ Firebase not available - apps: ${Firebase.apps.length}, _isFirebaseAvailable: $_isFirebaseAvailable');
      throw Exception('Firebase is not available. Please restart the app and check your internet connection.');
    }
    
    try {
      _setLoading(true);
      debugPrint('Resetting password for: $email');
      
      await _auth!.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserData() async {
    // Force reload by clearing cache
    _lastUserModelLoad = null;
    await _loadUserModel();
    notifyListeners();
  }

  Future<void> _initializeNotifications() async {
    try {
      // This would be called from the UI layer where NotificationService is available
      debugPrint('🔔 User authenticated, notifications should be initialized');
      // The actual initialization will be done in the UI layer
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  // Force refresh user data - useful for debugging
  Future<void> refreshUserData() async {
    debugPrint('🔄 Force refreshing user data...');
    await loadUserData();
    
    // If userModel is still null after loading, try to create a basic document
    if (_userModel == null && _user != null) {
      debugPrint('UserModel is still null, attempting to create basic user document...');
      await _createBasicUserDocument();
    }
  }

  Future<void> _createBasicUserDocument() async {
    if (!_isFirebaseAvailable || _user == null) return;
    
    try {
      debugPrint('Creating basic user document for existing user...');
      await _firestore!.collection('users').doc(_user!.uid).set({
        'uid': _user!.uid,
        'email': _user!.email ?? '',
        'fullName': _user!.displayName ?? 'User',
        'username': _user!.email?.split('@').first ?? 'user',
        'phoneNumber': '',
        'company': '',
        'position': '',
        'bio': '',
        'accountType': 'Public',
        'phoneNumberPrivacy': 'connections_only', // Default privacy setting
        'allowedPhoneViewers': [], // Empty list by default
        'socialLinks': {},
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      }, SetOptions(merge: true));
      
      debugPrint('✅ Basic user document created');
      await loadUserData();
    } catch (e) {
      debugPrint('❌ Error creating basic user document: $e');
    }
  }

  Future<void> updateUserModel(UserModel userModel) async {
    if (!_isFirebaseAvailable) {
      debugPrint('Firebase not available, cannot update user model');
      return;
    }
    
    try {
      _setLoading(true);
      debugPrint('Updating user model for: ${userModel.email}');
      
      await _firestore!.collection('users').doc(userModel.uid).update({
        'fullName': userModel.fullName,
        'profileImageUrl': userModel.profileImageUrl,
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': userModel.isOnline,
      });
      
      _userModel = userModel;
      notifyListeners();
      
      debugPrint('User model updated successfully');
    } catch (e) {
      debugPrint('Error updating user model: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile({
    required String fullName,
    String? username,
    String? bio,
    String? company,
    String? position,
    String? phoneNumber,
    String? profileImageUrl,
    Map<String, String>? socialLinks,
  }) async {
    if (!_isFirebaseAvailable) {
      debugPrint('Firebase not available, cannot update user profile');
      return;
    }
    
    try {
      _setLoading(true);
      final userId = _user?.uid ?? _userModel?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      debugPrint('Updating user profile for: $fullName');
      
      // Update Firebase Auth display name
      if (_user != null) {
        await _user!.updateDisplayName(fullName);
        if (profileImageUrl != null) {
          await _user!.updatePhotoURL(profileImageUrl);
        }
      }
      
      // Update Firestore user document
      final updateData = {
        'fullName': fullName,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (bio != null && bio.isNotEmpty) updateData['bio'] = bio;
      if (company != null && company.isNotEmpty) updateData['company'] = company;
      if (position != null && position.isNotEmpty) updateData['position'] = position;
      if (phoneNumber != null && phoneNumber.isNotEmpty) updateData['phoneNumber'] = phoneNumber;
      if (username != null && username.isNotEmpty) updateData['username'] = username;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        updateData['profileImageUrl'] = profileImageUrl;
      }
      if (socialLinks != null) {
        updateData['socialLinks'] = socialLinks;
      }
      
      await _firestore!.collection('users').doc(userId).update(updateData);
      
      // Update local user model
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(
          fullName: fullName,
          username: username ?? _userModel!.username,
          bio: bio ?? _userModel!.bio,
          company: company ?? _userModel!.company,
          position: position ?? _userModel!.position,
          phoneNumber: phoneNumber ?? _userModel!.phoneNumber,
          profileImageUrl: profileImageUrl ?? _userModel!.profileImageUrl,
          socialLinks: socialLinks ?? _userModel!.socialLinks,
        );
      }
      
      notifyListeners();
      debugPrint('User profile updated successfully');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePhonePrivacySettings({
    required String phoneNumberPrivacy,
    List<String>? allowedPhoneViewers,
  }) async {
    if (!_isFirebaseAvailable) {
      debugPrint('Firebase not available, cannot update phone privacy settings');
      return;
    }
    
    try {
      _setLoading(true);
      final userId = _user?.uid ?? _userModel?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      debugPrint('Updating phone privacy settings: $phoneNumberPrivacy');
      
             // Update Firestore user document
       final updateData = <String, dynamic>{
         'phoneNumberPrivacy': phoneNumberPrivacy,
         'lastSeen': FieldValue.serverTimestamp(),
         'updatedAt': FieldValue.serverTimestamp(),
       };
       
       // Clear allowedPhoneViewers if privacy is not 'custom'
       if (phoneNumberPrivacy != 'custom') {
         updateData['allowedPhoneViewers'] = [];
       } else if (allowedPhoneViewers != null) {
         updateData['allowedPhoneViewers'] = allowedPhoneViewers;
       }
       
       await _firestore!.collection('users').doc(userId).update(updateData);
       
       // Update local user model
       if (_userModel != null) {
         _userModel = _userModel!.copyWith(
           phoneNumberPrivacy: phoneNumberPrivacy,
           allowedPhoneViewers: phoneNumberPrivacy == 'custom' 
               ? (allowedPhoneViewers ?? _userModel!.allowedPhoneViewers)
               : [],
         );
       }
      
      notifyListeners();
      debugPrint('Phone privacy settings updated successfully');
    } catch (e) {
      debugPrint('Error updating phone privacy settings: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDigitalCardTheme(String themeId) async {
    if (!DigitalCardThemes.isValid(themeId)) {
      debugPrint('AuthService: Invalid digital card theme "$themeId"');
      return;
    }
    if (_user == null) {
      debugPrint('AuthService: Cannot update digital card theme without authenticated user');
      return;
    }

    final String previousTheme = digitalCardTheme;

    if (_userModel != null) {
      _userModel = _userModel!.copyWith(digitalCardTheme: themeId);
    }
    notifyListeners();

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('users').doc(_user!.uid).update({
          'digitalCardTheme': themeId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('AuthService: Digital card theme updated to $themeId');
      } catch (e) {
        debugPrint('AuthService: Failed to update digital card theme: $e');
        if (_userModel != null) {
          _userModel = _userModel!.copyWith(digitalCardTheme: previousTheme);
          notifyListeners();
        }
      }
    }
  }
}