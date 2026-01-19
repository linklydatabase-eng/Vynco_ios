import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using Vynco, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '2. Use License',
              'Permission is granted to temporarily download one copy of the materials (information or software) on Vynco for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose or for any public display\n• Attempt to decompile or reverse engineer any software contained on Vynco\n• Remove any copyright or other proprietary notations from the materials\n• Transfer the materials to another person or "mirror" the materials on any other server',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '3. Disclaimer',
              'The materials on Vynco are provided on an "as is" basis. Vynco makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '4. Limitations',
              'In no event shall Vynco or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Vynco.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '5. Accuracy of Materials',
              'The materials appearing on Vynco could include technical, typographical, or photographic errors. Vynco does not warrant that any of the materials on its website are accurate, complete, or current.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '6. Modifications',
              'Vynco may revise these terms of service for our website at any time without notice. By using this website, you are agreeing to be bound by the then current version of these terms of service.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '7. Governing Law',
              'These terms and conditions are governed by and construed in accordance with the laws of the jurisdiction in which Vynco is located, and you irrevocably submit to the exclusive jurisdiction of the courts in that location.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '8. User Conduct',
              'You agree not to post, upload, or transmit:\n\n• Content that is unlawful, harmful, or abusive\n• Spam or unsolicited commercial messages\n• Content that violates any intellectual property rights\n• Misinformation or false information\n• Harassing or threatening content',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '9. Contact Us',
              'If you have any questions about these Terms of Service, please contact us at support@vynco.app',
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
