import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../../utils/responsive_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _getErrorMessage(dynamic error) {
    String errorStr = error.toString();

    if (errorStr.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (errorStr.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (errorStr.contains('network-request-failed') ||
        errorStr.contains('network_error') ||
        errorStr.contains('Unable to resolve host')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (errorStr.contains('Exception: ')) {
      errorStr = errorStr.replaceFirst('Exception: ', '');
    }

    return errorStr.isNotEmpty
        ? errorStr
        : 'Could not send reset email. Please try again.';
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Password reset email sent. Please check your inbox.'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 4),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = _getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Forgot Password',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveUtils.getFontSize(context, baseSize: 18),
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
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 20, large: 24)),
                Text(
                  'Reset your password',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 24),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                Text(
                  'Enter the email associated with your account and we\'ll send you a secure link to reset your password.',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 32, medium: 36, large: 40)),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    final email = value.trim();
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(email)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            authService.isLoading ? null : _sendResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 0, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
                          ),
                        ),
                        child: authService.isLoading
                            ? SizedBox(
                                width: ResponsiveUtils.getIconSize(context, baseSize: 20),
                                height: ResponsiveUtils.getIconSize(context, baseSize: 20),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Send Reset Email',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, baseSize: 16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 24, medium: 28, large: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


