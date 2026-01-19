import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey900,
      appBar: AppBar(
        backgroundColor: AppColors.grey800,
        elevation: 0,
        title: const Text(
          'Terms of Service',
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
              _Heading('1. Introduction'),
              _Body(
                  'Welcome to Vynco. By creating an account or using our services, you agree to these Terms of Service. Please read them carefully.'),

              _Heading('2. Eligibility'),
              _Body(
                  'You must be at least 13 years old (or the minimum age required by law in your country) to use Vynco. By using Vynco, you represent that you meet this requirement.'),

              _Heading('3. Your Account'),
              _Body(
                  'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. Notify us immediately of any unauthorized use.'),

              _Heading('4. Acceptable Use'),
              _Body(
                  'You agree not to misuse Vynco, including but not limited to: posting unlawful content, impersonating others, scraping our services, or attempting to disrupt or compromise security.'),

              _Heading('5. Content and Licenses'),
              _Body(
                  'You retain ownership of the content you post. By posting content on Vynco, you grant us a non‑exclusive, worldwide, royalty‑free license to host and display it for the purpose of operating and improving our services.'),

              _Heading('6. Prohibited Content'),
              _Body(
                  'Content that is illegal, abusive, harassing, discriminatory, pornographic, spammy, or violates intellectual property rights is strictly prohibited and may lead to account suspension or removal.'),

              _Heading('7. Third‑Party Services'),
              _Body(
                  'Vynco may integrate with third‑party services (e.g., authentication, storage, analytics). Your use of those services is governed by their respective terms and privacy policies.'),

              _Heading('8. Termination'),
              _Body(
                  'We may suspend or terminate your access to Vynco at any time if you violate these Terms or if required by law. You may stop using Vynco at any time.'),

              _Heading('9. Disclaimers'),
              _Body(
                  'Vynco is provided “as is” without warranties of any kind. We do not guarantee uninterrupted or error‑free service.'),

              _Heading('10. Limitation of Liability'),
              _Body(
                  'To the maximum extent permitted by law, Vynco and its affiliates are not liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of data or profits.'),

              _Heading('11. Changes to these Terms'),
              _Body(
                  'We may update these Terms from time to time. When we do, we will update the “Last updated” date below. Continued use of Vynco after changes means you accept the updated Terms.'),

              _Heading('12. Contact'),
              _Body(
                  'Questions about these Terms? Contact support at vynco.help@gmail.com.'),

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


