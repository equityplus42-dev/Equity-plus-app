import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand color palette
  static const Color darkBg = Color(0xFF0C0A1C);
  static const Color cardBg = Color(0xFF171330);
  static const Color glassCardBg = Color(0x66171330);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryPink = Color(0xFFEC4899);
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color softGrey = Color(0xFF94A3B8);
  static const Color lightText = Color(0xFFF8FAFC);
  static const Color borderGrey = Color(0x2294A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryPink,
        surface: cardBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightText),
          displayMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightText),
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lightText),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: lightText),
          bodyLarge: const TextStyle(fontSize: 16, color: lightText),
          bodyMedium: const TextStyle(fontSize: 14, color: softGrey),
          bodySmall: const TextStyle(fontSize: 12, color: softGrey),
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderGrey, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        iconTheme: const IconThemeData(color: lightText),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPurple,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        labelStyle: GoogleFonts.outfit(color: softGrey),
        hintStyle: GoogleFonts.outfit(color: softGrey.withValues(alpha: 0.7)),
      ),
    );
  }

  // Premium background gradient decoration for scaffolds
  static BoxDecoration get bgGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkBg,
          Color(0xFF0F0C23),
          Color(0xFF090615),
        ],
      ),
    );
  }

  // Custom Glassmorphic card decoration
  static BoxDecoration glassCardDecoration() {
    return BoxDecoration(
      color: glassCardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderGrey, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
}
