import 'package:flutter/material.dart';

/// Utility class for responsive design across different screen sizes
class ResponsiveUtils {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  
  /// Get responsive padding based on screen width
  static EdgeInsets getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
  }
  
  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 16;
    } else if (width < tabletBreakpoint) {
      return 24;
    }
    return 32;
  }
  
  /// Get responsive vertical padding
  static double getVerticalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 12;
    } else if (width < tabletBreakpoint) {
      return 16;
    }
    return 20;
  }
  
  /// Get responsive spacing (SizedBox height/width)
  static double getSpacing(
    BuildContext context, {
    double small = 8,
    double medium = 12,
    double large = 16,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return small;
    } else if (width < tabletBreakpoint) {
      return medium;
    }

    return large;
  }
  
  /// Get responsive font size
  static double getFontSize(BuildContext context, {required double baseSize}) {
    final width = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2);
    
    if (width < mobileBreakpoint) {
      return baseSize * 0.95 * textScale;
    } else if (width < tabletBreakpoint) {
      return baseSize * textScale;
    }
    return baseSize * 1.05 * textScale;
  }
  
  /// Get responsive avatar size
  static double getAvatarSize(BuildContext context, {double small = 40, double medium = 50, double large = 60}) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return small;
    } else if (width < tabletBreakpoint) {
      return medium;
    }
    return large;
  }
  
  /// Get responsive icon size
  static double getIconSize(BuildContext context, {double baseSize = 24}) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return baseSize * 0.9;
    } else if (width < tabletBreakpoint) {
      return baseSize;
    }
    return baseSize * 1.1;
  }
  
  /// Get responsive card max width
  static double getCardMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return double.infinity;
    } else if (width < tabletBreakpoint) {
      return 500;
    }
    return 600;
  }
  
  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 44;
    } else if (width < tabletBreakpoint) {
      return 48;
    }
    return 52;
  }
  
  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  /// Get responsive border radius
  static double getBorderRadius(BuildContext context, {double base = 12}) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return base * 0.9;
    } else if (width < tabletBreakpoint) {
      return base;
    }
    return base * 1.1;
  }
  
  /// Get responsive EdgeInsets.all padding
  static EdgeInsets getAllPadding(BuildContext context, {double base = 16}) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return EdgeInsets.all(base * 0.75);
    } else if (width < tabletBreakpoint) {
      return EdgeInsets.all(base);
    }
    return EdgeInsets.all(base * 1.25);
  }
  
  /// Get responsive EdgeInsets.symmetric padding
  static EdgeInsets getSymmetricPadding(
    BuildContext context, {
    double horizontal = 16,
    double vertical = 12,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return EdgeInsets.symmetric(
        horizontal: horizontal * 0.75,
        vertical: vertical * 0.75,
      );
    } else if (width < tabletBreakpoint) {
      return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
    }
    return EdgeInsets.symmetric(
      horizontal: horizontal * 1.25,
      vertical: vertical * 1.25,
    );
  }
  
  /// Get responsive EdgeInsets.only padding
  static EdgeInsets getOnlyPadding(
    BuildContext context, {
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final width = MediaQuery.of(context).size.width;
    final multiplier = width < mobileBreakpoint ? 0.75 : (width < tabletBreakpoint ? 1.0 : 1.25);
    
    return EdgeInsets.only(
      left: (left ?? 0) * multiplier,
      top: (top ?? 0) * multiplier,
      right: (right ?? 0) * multiplier,
      bottom: (bottom ?? 0) * multiplier,
    );
  }
  
  /// Get responsive screen width percentage
  static double getWidthPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }
  
  /// Get responsive screen height percentage
  static double getHeightPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }
  
  /// Get responsive container width (with max constraint)
  static double getContainerWidth(BuildContext context, {double? maxWidth}) {
    final width = MediaQuery.of(context).size.width;
    if (maxWidth != null && width > maxWidth) {
      return maxWidth;
    }
    return width;
  }
}

