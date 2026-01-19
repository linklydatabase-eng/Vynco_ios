import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.grey900,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.grey900,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: January 2026',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Introduction',
              'Vynco is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our digital business card and networking application.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Information We Collect',
              'We collect information you provide directly to us, such as:\n\n• Profile information (name, email, phone number)\n• Profile picture and bio\n• Social media links\n• Location data (when shared)\n• Device information\n• Usage analytics',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'How We Use Your Information',
              'We use the information we collect to:\n\n• Create and manage your digital business card\n• Facilitate networking connections\n• Improve our services\n• Send notifications and updates\n• Analyze user behavior and preferences\n• Comply with legal obligations',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Third-Party Sharing',
              'We do not sell your personal information to third parties. We may share information with service providers who assist us in operating our application and conducting our business.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Your Rights',
              'You have the right to:\n\n• Access your personal information\n• Correct inaccurate data\n• Request deletion of your data\n• Opt-out of marketing communications\n• Withdraw consent at any time',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Contact Us',
              'If you have questions about this Privacy Policy, please contact us at privacy@vynco.app',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
