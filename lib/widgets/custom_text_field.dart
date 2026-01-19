import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;
  final Color? borderColor;
  final Color? focusedBorderColor;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.borderColor,
    this.focusedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
        ClipRRect(
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? [
                          const Color(0xFF1F295B).withOpacity(0.6),
                          const Color(0xFF283B89).withOpacity(0.5),
                        ]
                      : [
                          const Color(0xFF2A2F50).withOpacity(0.4),
                          const Color(0xFF1A1F3A).withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                border: Border.all(
                  color: enabled
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                validator: validator,
                onChanged: onChanged,
                maxLines: maxLines,
                enabled: enabled,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                  color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                  prefixIcon: prefixIcon != null
                      ? Icon(
                          prefixIcon,
                          color: AppColors.textPrimary.withOpacity(0.7),
                          size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                        )
                      : null,
                  suffixIcon: suffixIcon,
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                    borderSide: BorderSide(
                      color: focusedBorderColor ?? AppColors.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                    borderSide: const BorderSide(color: AppColors.error, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                    borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: ResponsiveUtils.getSymmetricPadding(
                    context,
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
