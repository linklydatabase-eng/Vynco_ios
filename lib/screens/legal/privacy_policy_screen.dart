import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey900,
      appBar: AppBar(
        backgroundColor: AppColors.grey800,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Heading('1. Overview'),
              _Body(
                  'This Privacy Policy explains how Vynco collects, uses, and protects your information when you use our services.'),

              _Heading('2. Information We Collect'),
              _Body(
                  'We collect information you provide (such as name, email, phone, profile details), information generated when you use the app (such as posts, connections, messages metadata), and device information for performance and security.'),

              _Heading('3. How We Use Information'),
              _Body(
                  'We use your information to operate Vynco, personalize your experience, connect you with other users, secure our services, and comply with legal obligations.'),

              _Heading('4. Sharing of Information'),
              _Body(
                  'We do not sell your personal data. We may share information with service providers (e.g., cloud hosting, analytics, notifications) under strict confidentiality obligations, and as required by law.'),

              _Heading('5. Data Retention'),
              _Body(
                  'We retain your information for as long as necessary to provide our services and comply with legal requirements. You may request deletion of your account to remove personal data, subject to legal exceptions.'),

              _Heading('6. Your Choices'),
              _Body(
                  'You can update your profile, manage notifications, and control the visibility of your information in app settings.'),

              _Heading('7. Security'),
              _Body(
                  'We use industry‑standard measures to protect your data. However, no system is 100% secure; use strong passwords and keep them confidential.'),

              _Heading('8. Children’s Privacy'),
              _Body(
                  'Vynco is not intended for children under 13. If we learn that we have collected personal data from a child under 13, we will take steps to delete it.'),

              _Heading('9. International Transfers'),
              _Body(
                  'Your data may be processed in countries other than your own. We ensure adequate protections are in place as required by applicable law.'),

              _Heading('10. Changes to this Policy'),
              _Body(
                  'We may update this Privacy Policy from time to time. Continued use of Vynco after changes means you accept the updated Policy.'),

              _Heading('11. Contact Us'),
              _Body(
                  'If you have questions about this Policy, contact us at vynco.help@gmail.com.'),

              SizedBox(height: 16),
              Text(
                'Last updated: Oct 29, 2025',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.6,
      ),
    );
  }
}


