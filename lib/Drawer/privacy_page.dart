import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header("EasyInvoice Privacy Policy"),
            const SizedBox(height: 10),

            _paragraph(
              "Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
            ),

            const SizedBox(height: 25),

            _sectionTitle("1. Introduction"),
            _paragraph(
              "Thank you for using EasyInvoice. Your privacy is important to us. "
              "This Privacy Policy explains how we handle and protect your information.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("2. No Collection of Personal Data"),
            _paragraph(
              "EasyReceipt does **not collect, store, transmit, or share any personal data** "
              "on external servers or cloud databases.",
            ),
            _paragraph(
              "All the data you enter—such as invoice details, customer information, or templates—"
              "is stored **locally on your device only**.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("3. Local Device Storage"),
            _paragraph(
              "Your data stays on your phone using secure local storage (SharedPreferences / local files). "
              "We cannot access, view, or recover your information.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("4. Data Deletion"),
            _paragraph(
              "When you uninstall the app or clear its storage, **all data is permanently deleted**. "
              "We do not keep any backups.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("5. Permissions Used"),
            _paragraph(
              "EasyReceipt may request the following permissions solely for app functionality:",
            ),
            _bullet(
              "Storage – Used only to save invoices/screenshots on your device.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("6. No Tracking or Analytics"),
            _paragraph(
              "EasyReceipt does **not** use analytics tools, tracking SDKs, advertising IDs, or cookies.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("7. Third-Party Services"),
            _paragraph(
              "The app does not use third-party servers, databases, or APIs that store or process user data.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("8. Children’s Privacy"),
            _paragraph(
              "EasyReceipt does not knowingly collect personal data from children under 13. "
              "Since no online data collection occurs, the app remains safe for all age groups.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("9. Changes to This Policy"),
            _paragraph(
              "We may update this Privacy Policy if required for app improvements or legal compliance. "
              "Any changes will be reflected here.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("10. Contact Us"),
            _paragraph(
              "If you have any questions about this Privacy Policy, you can contact us at:",
            ),
            _paragraph("📧 Email: support.farhanappdev@gmail.com"),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      height: 1.3,
      color: Colors.black87,
    ),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade700,
    ),
  );

  Widget _paragraph(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        height: 1.55,
        color: Colors.black87,
      ),
    ),
  );

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(left: 8, top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("•  "),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              height: 1.55,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
