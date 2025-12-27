import 'Home/homepage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(EasyReceiptApp());

class EasyReceiptApp extends StatelessWidget {
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF212121);
  static const Color accent = Color(0xFF64B5F6);

  const EasyReceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EasyReceipt',
      theme: ThemeData(
        scaffoldBackgroundColor: background,
        primaryColor: primary,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: primary,
          secondary: accent,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: primaryDark),
          titleTextStyle: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.inter(color: textColor, fontSize: 14),
          bodyMedium: GoogleFonts.inter(
            color: textColor.withAlpha((0.8 * 255).round()),
            fontSize: 13,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accent,
        ),
      ),
      home: HomePage(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const EasyReceiptApp();
  }
}
