import 'package:EasyInvoice/Drawer/Security/security_service.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';
import 'package:EasyInvoice/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool authorized = await SecurityService.requireAppLock();

  if (authorized) {
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const EasyReceiptApp(),
      ),
    );
  } else {
    SystemNavigator.pop();
  }
}

class EasyReceiptApp extends StatelessWidget {
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF212121);
  static const Color accent = Color(0xFF64B5F6);

  const EasyReceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AnimatedTheme(
          data: themeProvider.isDarkMode
              ? ThemeProvider.darkTheme
              : ThemeProvider.lightTheme,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EasyReceipt',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
          ),
        );
      },
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
