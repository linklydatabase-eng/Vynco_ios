import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isEmailMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(dynamic error) {
    String errorStr = error.toString();
    
    // Handle network errors
    if (errorStr.contains('network-request-failed') || 
        errorStr.contains('network_error') ||
        errorStr.contains('Unable to resolve host')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    // Handle Firebase auth errors
    if (errorStr.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (errorStr.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errorStr.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (errorStr.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    }
    if (errorStr.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    }
    
    // Clean up generic exception formatting
    if (errorStr.contains('Exception: ')) {
      errorStr = errorStr.replaceFirst('Exception: ', '');
    }
    if (errorStr.contains('Exception')) {
      errorStr = errorStr.replaceFirst('Exception', '').trim();
      if (errorStr.startsWith(':')) {
        errorStr = errorStr.substring(1).trim();
      }
    }
    
    // Remove Firebase error code prefix if present
    if (errorStr.contains('[firebase_auth/')) {
      final match = RegExp(r'\[firebase_auth/[^\]]+\]\s*(.+)').firstMatch(errorStr);
      if (match != null && match.groupCount >= 1) {
        errorStr = match.group(1) ?? errorStr;
      }
    }
    
    return errorStr.isNotEmpty ? errorStr : 'Sign in failed. Please try again.';
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithUsernameOrEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Wait for auth state to update (poll up to 3 seconds)
      int attempts = 0;
      const maxAttempts = 30; // 30 * 100ms = 3 seconds
      
      while (attempts < maxAttempts && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (authService.isAuthenticated) {
          break;
        }
        attempts++;
      }
      
      // Navigate if authenticated
      if (mounted && authService.isAuthenticated) {
        context.go('/home');
      } else if (mounted) {
        // If still not authenticated after waiting, show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in completed but authentication failed. Please try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithApple();
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        // Check if user cancelled
        if (e.toString().toLowerCase().contains('canceled') || 
            e.toString().toLowerCase().contains('cancelled') ||
            e.toString().toLowerCase().contains('user closed')) {
          // Silently handle user cancellation
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed. Please try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight, // Professional light background
      appBar: AppBar(
        backgroundColor: AppColors.white, // Clean white app bar
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.go('/onboarding'),
        ),
        title: const Text(
          'Sign In',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getAllPadding(context, base: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 20, medium: 24, large: 28)),
                
                // Title
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 32),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                Text(
                  'Welcome back to Vynco',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 16),
                    color: AppColors.textSecondary,
                  ),
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 30, medium: 32, large: 36)),
                
                // Email/Username Toggle with glass effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, small: 4, medium: 5, large: 6)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1F295B).withOpacity(0.85),
                            const Color(0xFF283B89).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isEmailMode = true;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSpacing(context, small: 12, medium: 14, large: 16)),
                                decoration: BoxDecoration(
                                  color: _isEmailMode ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                ),
                                child: Text(
                                  'Email',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isEmailMode ? Colors.white : Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isEmailMode = false;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getSpacing(context, small: 12, medium: 14, large: 16)),
                                decoration: BoxDecoration(
                                  color: !_isEmailMode ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                ),
                                child: Text(
                                  'Username',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isEmailMode ? Colors.white : Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 30, medium: 32, large: 36)),
                
                // Email/Username field with glass effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1F295B).withOpacity(0.85),
                            const Color(0xFF283B89).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
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
                      child: Padding(
                        padding: ResponsiveUtils.getAllPadding(context, base: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEmailMode ? 'Email Address' : 'Username',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, baseSize: 13),
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                            Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: const TextSelectionThemeData(
                                  selectionColor: AppColors.primary,
                                  cursorColor: AppColors.primary,
                                ),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: _isEmailMode ? TextInputType.emailAddress : TextInputType.text,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: _isEmailMode ? 'Enter your email' : 'Enter your username',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.2,
                                  ),
                                  prefixIcon: Icon(
                                    _isEmailMode ? Icons.email_outlined : Icons.person_outlined,
                                    color: Colors.white.withOpacity(0.7),
                                    size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: const BorderSide(color: AppColors.error, width: 1),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                  ),
                                  contentPadding: ResponsiveUtils.getSymmetricPadding(
                                    context,
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return _isEmailMode ? 'Please enter your email' : 'Please enter your username';
                                  }
                                  if (_isEmailMode && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  if (!_isEmailMode && value.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  if (!_isEmailMode && !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                                    return 'Username can only contain letters, numbers, and underscores';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 20, medium: 24, large: 28)),
                
                // Password field with glass effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1F295B).withOpacity(0.85),
                            const Color(0xFF283B89).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
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
                      child: Padding(
                        padding: ResponsiveUtils.getAllPadding(context, base: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, baseSize: 13),
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                            Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: const TextSelectionThemeData(
                                  selectionColor: AppColors.primary,
                                  cursorColor: AppColors.primary,
                                ),
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.2,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outlined,
                                    color: Colors.white.withOpacity(0.7),
                                    size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.white.withOpacity(0.7),
                                      size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: const BorderSide(color: AppColors.error, width: 1),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                                    borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                  ),
                                  contentPadding: ResponsiveUtils.getSymmetricPadding(
                                    context,
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 20, medium: 24, large: 28)),
                
                // Remember me and forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/forgot-password');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 30, medium: 32, large: 36)),
                
                // Sign in button
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    return CustomButton(
                      text: 'Sign In',
                      onPressed: authService.isLoading ? null : _signIn,
                      isLoading: authService.isLoading,
                    );
                  },
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 30, medium: 32, large: 36)),
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.grey300)),
                    Padding(
                      padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 16, vertical: 0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.grey300)),
                  ],
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 30, medium: 32, large: 36)),
                
                // Google sign in button
                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Icon(
                    Icons.g_mobiledata,
                    size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                    color: AppColors.grey600,
                  ),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontSize: ResponsiveUtils.getFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 0, vertical: 16),
                    side: const BorderSide(color: AppColors.grey300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                    ),
                    backgroundColor: AppColors.white,
                  ),
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 18, large: 20)),
                
                // Apple sign in button
                OutlinedButton.icon(
                  onPressed: _signInWithApple,
                  icon: Icon(
                    Icons.apple,
                    size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                    color: AppColors.grey600,
                  ),
                  label: Text(
                    'Continue with Apple ID',
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontSize: ResponsiveUtils.getFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 0, vertical: 16),
                    side: const BorderSide(color: AppColors.grey300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                    ),
                    backgroundColor: AppColors.white,
                  ),
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 40, medium: 44, large: 48)),
                
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
