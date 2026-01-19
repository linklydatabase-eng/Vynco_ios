import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  FirebaseFirestore? _firestore;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isFirebaseAvailable = false;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isFirebaseAvailable => _isFirebaseAvailable;
  bool get isAuthenticated => _user != null || (_userModel != null && !_isFirebaseAvailable);

  AuthService({bool firebaseInitialized = true}) {
    if (firebaseInitialized) {
      try {
        _auth = FirebaseAuth.instance;
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        _firestore = FirebaseFirestore.instance;
        _isFirebaseAvailable = true;
        _auth!.authStateChanges().listen(_onAuthStateChanged);
        debugPrint('✅ AuthService initialized with REAL Firebase authentication');
        debugPrint('✅ Users will be created in Firebase Console');
        debugPrint('✅ Only registered users can sign in');
      } catch (e) {
        debugPrint('❌ AuthService initialized without Firebase: $e');
        _isFirebaseAvailable = false;
        _initializeMockUser();
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
      _loadUserModel();
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserModel() async {
    if (_user == null || _firestore == null) return;
    
    try {
      final doc = await _firestore!.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userModel = UserModel.fromMap(data);
      }
    } catch (e) {
      debugPrint('Error loading user model: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_isFirebaseAvailable) {
      throw Exception('Firebase is not available. Please check your internet connection.');
    }
    
    try {
      _setLoading(true);
      debugPrint('Signing in with email: $email');
      
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }
      
      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }
      
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      debugPrint('Sign in successful for: $email');
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
      } else {
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password, String fullName) async {
    if (!_isFirebaseAvailable) {
      throw Exception('Firebase is not available. Please check your internet connection.');
    }
    
    try {
      _setLoading(true);
      debugPrint('Signing up with email: $email, name: $fullName');
      
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw Exception('All fields are required');
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
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
      }
      
      debugPrint('Sign up successful for: $email');
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

  Future<UserCredential?> signInWithGoogle() async {
    if (!_isFirebaseAvailable) {
      throw Exception('Firebase is not available. Please check your internet connection.');
    }
    
    try {
      _setLoading(true);
      debugPrint('Signing in with Google');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in was cancelled by user');
        return null;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth!.signInWithCredential(credential);
      
      // Create or update user document in Firestore
      if (userCredential.user != null) {
        await _firestore!.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email ?? '',
          'fullName': userCredential.user!.displayName ?? 'Google User',
          'profileImageUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        }, SetOptions(merge: true));
      }
      
      debugPrint('Google sign in successful for: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      if (e.toString().contains('network_error')) {
        throw Exception('Network error. Please check your internet connection');
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception('Google sign-in failed. Please try again');
      } else if (e.toString().contains('PigeonUserDetails')) {
        throw Exception('Authentication service error. Please try again');
      } else {
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      debugPrint('Signing out');
      
      if (_isFirebaseAvailable) {
        // Sign out from Firebase Auth
        await _auth!.signOut();
        debugPrint('✅ Firebase Auth sign out successful');
        
        // Sign out from Google Sign-In
        await _googleSignIn!.signOut();
        debugPrint('✅ Google Sign-In sign out successful');
      } else {
        debugPrint('✅ Local authentication sign out');
      }
      
      // Clear user data
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
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    if (!_isFirebaseAvailable) {
      throw Exception('Firebase is not available. Please check your internet connection.');
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
}
