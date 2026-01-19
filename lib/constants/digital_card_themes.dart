import 'package:flutter/material.dart';

class DigitalCardThemeData {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  const DigitalCardThemeData({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
  });
}

class DigitalCardThemes {
  static const String defaultThemeId = 'sapphire-night';

  static const List<DigitalCardThemeData> themes = [
    DigitalCardThemeData(
      id: 'sapphire-night',
      name: 'Sapphire Night',
      gradientColors: [
        Color(0xFF0D47A1),
        Color(0xFF002171),
      ],
      borderColor: Color(0xFF6B8FAE),
      shadowColor: Color(0xFF0D47A1),
      textPrimaryColor: Colors.white,
      textSecondaryColor: Color(0xFFE0E7FF),
    ),
    DigitalCardThemeData(
      id: 'aurora-sunset',
      name: 'Aurora Sunset',
      gradientColors: [
        Color(0xFFFF7E5F),
        Color(0xFFFD3A84),
      ],
      borderColor: Color(0xFFFF9A8B),
      shadowColor: Color(0xFFFD3A84),
      textPrimaryColor: Color(0xFF2C1A1A),
      textSecondaryColor: Color(0xFF5C3B40),
    ),
    DigitalCardThemeData(
      id: 'emerald-horizon',
      name: 'Emerald Horizon',
      gradientColors: [
        Color(0xFF0BAB64),
        Color(0xFF3BB78F),
      ],
      borderColor: Color(0xFF5DD39E),
      shadowColor: Color(0xFF0BAB64),
      textPrimaryColor: Color(0xFF06251B),
      textSecondaryColor: Color(0xFF0C4B39),
    ),
    DigitalCardThemeData(
      id: 'plum-galaxy',
      name: 'Plum Galaxy',
      gradientColors: [
        Color(0xFF654EA3),
        Color(0xFFEA4C89),
      ],
      borderColor: Color(0xFFD17FFF),
      shadowColor: Color(0xFF654EA3),
      textPrimaryColor: Colors.white,
      textSecondaryColor: Color(0xFFEEDBFF),
    ),
    DigitalCardThemeData(
      id: 'ocean-breeze',
      name: 'Ocean Breeze',
      gradientColors: [
        Color(0xFF00C9FF),
        Color(0xFF92FE9D),
      ],
      borderColor: Color(0xFF4DD0E1),
      shadowColor: Color(0xFF00C9FF),
      textPrimaryColor: Color(0xFF0A1F2E),
      textSecondaryColor: Color(0xFF1A4A5A),
    ),
    DigitalCardThemeData(
      id: 'midnight-sky',
      name: 'Midnight Sky',
      gradientColors: [
        Color(0xFF2C3E50),
        Color(0xFF000000),
      ],
      borderColor: Color(0xFF5A6C7D),
      shadowColor: Color(0xFF1A1A2E),
      textPrimaryColor: Colors.white,
      textSecondaryColor: Color(0xFFB8C5D6),
    ),
    DigitalCardThemeData(
      id: 'coral-reef',
      name: 'Coral Reef',
      gradientColors: [
        Color(0xFFFF6B6B),
        Color(0xFFFFA07A),
      ],
      borderColor: Color(0xFFFF8787),
      shadowColor: Color(0xFFFF6B6B),
      textPrimaryColor: Color(0xFF2C1810),
      textSecondaryColor: Color(0xFF4D2E20),
    ),
    DigitalCardThemeData(
      id: 'forest-mist',
      name: 'Forest Mist',
      gradientColors: [
        Color(0xFF134E5E),
        Color(0xFF71B280),
      ],
      borderColor: Color(0xFF4A9B6E),
      shadowColor: Color(0xFF134E5E),
      textPrimaryColor: Colors.white,
      textSecondaryColor: Color(0xFFE0F4E5),
    ),
    DigitalCardThemeData(
      id: 'royal-gold',
      name: 'Royal Gold',
      gradientColors: [
        Color(0xFFFFD700),
        Color(0xFFFF8C00),
      ],
      borderColor: Color(0xFFFFB347),
      shadowColor: Color(0xFFFF8C00),
      textPrimaryColor: Color(0xFF2C1A0A),
      textSecondaryColor: Color(0xFF5C3A1A),
    ),
    DigitalCardThemeData(
      id: 'lavender-dreams',
      name: 'Lavender Dreams',
      gradientColors: [
        Color(0xFFE0B0FF),
        Color(0xFFFFB6E1),
      ],
      borderColor: Color(0xFFE6C5FF),
      shadowColor: Color(0xFFDDA0DD),
      textPrimaryColor: Color(0xFF2E1A2E),
      textSecondaryColor: Color(0xFF4D2E4D),
    ),
    DigitalCardThemeData(
      id: 'mint-fresh',
      name: 'Mint Fresh',
      gradientColors: [
        Color(0xFF00F5FF),
        Color(0xFF00D4AA),
      ],
      borderColor: Color(0xFF4DEDCC),
      shadowColor: Color(0xFF00D4AA),
      textPrimaryColor: Color(0xFF0A2E2A),
      textSecondaryColor: Color(0xFF1A4A45),
    ),
    DigitalCardThemeData(
      id: 'amber-glow',
      name: 'Amber Glow',
      gradientColors: [
        Color(0xFFFFB347),
        Color(0xFFFF6B35),
      ],
      borderColor: Color(0xFFFFA07A),
      shadowColor: Color(0xFFFF6B35),
      textPrimaryColor: Color(0xFF2E1A0A),
      textSecondaryColor: Color(0xFF4D2E1A),
    ),
    DigitalCardThemeData(
      id: 'twilight-purple',
      name: 'Twilight Purple',
      gradientColors: [
        Color(0xFF667EEA),
        Color(0xFF764BA2),
      ],
      borderColor: Color(0xFF8B7FD8),
      shadowColor: Color(0xFF764BA2),
      textPrimaryColor: Colors.white,
      textSecondaryColor: Color(0xFFE0D4FF),
    ),
  ];

  static DigitalCardThemeData themeById(String id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }

  static bool isValid(String id) {
    return themes.any((theme) => theme.id == id);
  }

  static String nameForId(String id) {
    return themeById(id).name;
  }
}

