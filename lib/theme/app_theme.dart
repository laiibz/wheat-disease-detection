import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color darkBotanicalGreen = Color(0xFF142B1A); 
  static const Color sageGreen = Color(0xFF8DAA91);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color cardColor = Color(0xFF1C3524);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBotanicalGreen,
      primaryColor: goldAccent,
      cardColor: cardColor,
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: sageGreen,
        surface: cardColor,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineMedium: GoogleFonts.philosopher(
          textStyle: const TextStyle(
            color: goldAccent,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        bodyMedium: const TextStyle(color: sageGreen, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: goldAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassWhite,
        labelStyle: const TextStyle(color: sageGreen),
        prefixIconColor: sageGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F4F1), // Light Sage/Grey
      primaryColor: const Color(0xFF1B3D26),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1B3D26),
        secondary: Color(0xFFD4AF37),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
        headlineMedium: GoogleFonts.philosopher(
          textStyle: const TextStyle(
            color: Color(0xFF1B3D26),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        titleLarge: const TextStyle(color: Color(0xFF1B3D26), fontWeight: FontWeight.bold, fontSize: 18),
        bodyMedium: const TextStyle(color: Color(0xFF4A5D4E), fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B3D26),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B3D26),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
    );
  }
}
