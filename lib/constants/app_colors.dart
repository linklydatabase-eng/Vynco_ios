import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Deep Blue Gradient for Cards (#0D47A1 → #002171)
  static const Color primary = Color(0xFF0D47A1); // Deep Blue
  static const Color primaryLight = Color(0xFF1565C0); // Medium Deep Blue
  static const Color primaryDark = Color(0xFF002171); // Navy
  
  // Secondary Colors - Orange to Gold Gradient for Actions (#F79E1B → #FFB300)
  static const Color secondary = Color(0xFFF79E1B); // Orange
  static const Color secondaryLight = Color(0xFFFFB300); // Gold
  static const Color secondaryDark = Color(0xFFE68900); // Darker Orange
  
  // Accent Colors - Warm Yellow Highlights
  static const Color accent = Color(0xFFF8B334); // Warm Yellow
  static const Color accentLight = Color(0xFFFFC947); // Light Warm Yellow
  static const Color accentDark = Color(0xFFE6A500); // Darker Yellow
  
  // Neutral Colors - Text on Dark Panels
  static const Color white = Color(0xFFFFFFFF); // Bright White
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFF1A2436); // Deep Neutral for Panels/Modals
  static const Color grey100 = Color(0xFFB0B8C5); // Muted Gray for Secondary Text
  static const Color grey200 = Color(0xFF9CA3B0); // Medium Muted Gray
  static const Color grey300 = Color(0xFF7A8190); // Medium Gray
  static const Color grey400 = Color(0xFF5A6375); // Medium Dark Gray
  static const Color grey500 = Color(0xFF4A5263); // Dark Gray
  static const Color grey600 = Color(0xFF3A4152); // Darker Gray
  static const Color grey700 = Color(0xFF2C2F48); // Dark Violet for Secondary Buttons
  static const Color grey800 = Color(0xFF101B2D); // Sidebar/AppBar Background
  static const Color grey900 = Color(0xFF0E1624); // Overall Background
  
  // 🔤 Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Bright White for Primary Text
  static const Color textSecondary = Color(0xFFB0B8C5); // Muted Gray for Secondary Text
  static const Color textMuted = Color(0xFFE1E6F0); // Light Purple for Muted Text
  
  // Status Colors
  static const Color success = Color(0xFF0D47A1); // Deep Blue
  static const Color warning = Color(0xFFF8B334); // Warm Yellow
  static const Color error = Color(0xFFE53E3E); // Red for liked hearts
  static const Color info = Color(0xFFE1E6F0); // Light Purple for Icons
  
  // Background Colors - Fintech Dashboard Theme
  static const Color backgroundLight = Color(0xFF1A2436); // Deep Neutral for Panels
  static const Color backgroundDark = Color(0xFF0E1624); // Overall Dark Navy-Black
  static const Color surfaceLight = Color(0xFF1A2436); // Panels and Modals
  static const Color surfaceDark = Color(0xFF101B2D); // Sidebar Background
  
  // Card Theme Colors - Deep Blue Gradient Cards
  static const Color navyCard = Color(0xFF002171); // Navy (end of gradient)
  static const Color platinumCard = Color(0xFFE1E6F0); // Light Purple for Icons
  static const Color emeraldCard = Color(0xFF0D47A1); // Deep Blue (start of gradient)
  static const Color amberCard = Color(0xFFF8B334); // Warm Yellow Highlights
  static const Color roseCard = Color(0xFFF79E1B); // Orange
  static const Color indigoCard = Color(0xFF0D47A1); // Deep Blue
  
  // Gradient Colors - Fintech Dashboard Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF002171)], // Deep Blue to Navy
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFF79E1B), Color(0xFFFFB300)], // Orange to Gold
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF79E1B), Color(0xFFFFB300)], // Orange to Gold for Actions
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Additional gradients
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF002171)], // Deep Blue to Navy for Cards
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFF79E1B), Color(0xFFFFB300)], // Orange to Gold
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
