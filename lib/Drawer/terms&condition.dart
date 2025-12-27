import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Terms & Conditions",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header("Welcome to EasyInvoice"),
            _text(
              "These Terms & Conditions outline the rules and guidelines for using the EasyInvoice mobile application. "
              "By installing or using this app, you automatically agree to these terms.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("1. Acceptance of Terms"),
            _text(
              "By accessing or using EasyInvoice, you agree to abide by these Terms & Conditions. "
              "If you do not agree, please discontinue using the app immediately.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("2. Offline-Only Functionality"),
            _text(
              "EasyInvoice works entirely offline. All data you create (invoices, items, client details, templates) "
              "is stored locally on your device. We do not collect, upload, store, or process any user data on external servers.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("3. User Responsibilities"),
            _text(
              "You are responsible for maintaining the security of your device and any invoices or business data you store. "
              "EasyInvoice is not responsible for any data loss caused by:",
            ),
            _bullets([
              "Uninstalling the app",
              "Clearing app storage",
              "Factory reset",
              "Device damage or malfunction",
              "User mistake or accidental deletion",
            ]),

            const SizedBox(height: 25),

            _sectionTitle("4. Accuracy of Information"),
            _text(
              "While EasyInvoice helps generate professional invoices, the accuracy of business information, pricing, "
              "tax calculations, and client details entered into the app is solely your responsibility.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("5. Prohibited Actions"),
            _text("You agree NOT to:"),
            _bullets([
              "Modify, hack, or reverse-engineer the app",
              "Use the app for illegal or fraudulent activities",
              "Distribute invoices containing false or misleading information",
              "Sell, rent, or resell the app's code or UI",
            ]),

            const SizedBox(height: 25),

            _sectionTitle("6. Intellectual Property"),
            _text(
              "All design elements, icons, UI components, features, and branding in EasyInvoice are the intellectual property "
              "of the app creator. You may use the app but cannot duplicate or resell the design or code.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("7. No Warranties"),
            _text(
              "EasyInvoice is provided \"as-is\" without warranties of any kind. "
              "We do not guarantee error-free performance, though we strive to improve continuously.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("8. Limitation of Liability"),
            _text(
              "To the maximum extent permitted by law, EasyInvoice is not liable for any:",
            ),
            _bullets([
              "Loss of business data",
              "Financial damages",
              "Loss of revenue",
              "App misuse",
              "Unexpected bugs or crashes",
            ]),

            const SizedBox(height: 25),

            _sectionTitle("9. Updates & Changes"),
            _text(
              "We may update these terms at any time to improve security, UX, or comply with regulations. "
              "Continued use after updates means you accept the revised terms.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("10. Contact Information"),
            _text(
              "If you have questions about these Terms & Conditions, you may contact us at:",
            ),
            _textBold("📧 support.farhanappdev@gmail.com"),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0D47A1),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1565C0),
      ),
    );
  }

  Widget _text(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _textBold(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _bullets(List<String> items) {
    return Column(
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("•  ", style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      e,
                      style: GoogleFonts.inter(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
