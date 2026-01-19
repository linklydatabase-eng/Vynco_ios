import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/privacy_utils.dart';

class DigitalCardPreview extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userCompany;
  final String? userPosition;
  final String accountType;
  final bool isConnected;

  const DigitalCardPreview({
    super.key,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userCompany,
    this.userPosition,
    this.accountType = 'Public',
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to full card view
      },
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            
            // Card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? '',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userPosition ?? '',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Share profile
                        },
                        icon: const Icon(
                          Icons.share,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    userCompany ?? '',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        color: AppColors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        PrivacyUtils.getPersonalInfoDisplay(
                          personalInfo: userEmail,
                          accountType: accountType,
                          isConnected: isConnected,
                          placeholder: 'Connect to view',
                        ),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        color: AppColors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        PrivacyUtils.getPersonalInfoDisplay(
                          personalInfo: userPhone,
                          accountType: accountType,
                          isConnected: isConnected,
                          placeholder: 'Connect to view',
                        ),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // QR Code indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.qr_code,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
