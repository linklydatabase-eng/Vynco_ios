import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSmall;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSmall = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? (isSmall 
        ? ResponsiveUtils.getButtonHeight(context) * 0.72 
        : ResponsiveUtils.getButtonHeight(context));
    final iconSize = isSmall 
        ? ResponsiveUtils.getIconSize(context, baseSize: 16)
        : ResponsiveUtils.getIconSize(context, baseSize: 20);
    final fontSize = isSmall 
        ? ResponsiveUtils.getFontSize(context, baseSize: 12)
        : ResponsiveUtils.getFontSize(context, baseSize: 16);
    
    return SizedBox(
      width: width ?? double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 8)),
          ),
          disabledBackgroundColor: AppColors.grey300,
          disabledForegroundColor: AppColors.grey500,
        ),
        child: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: iconSize),
                    SizedBox(width: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
