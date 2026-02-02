import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: colors.background,
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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 800 : double.infinity,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(
                  "EasyInvoice Privacy Policy",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 10),
                _paragraph(
                  "Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 25),
                _sectionTitle("1. Introduction"),
                _paragraph(
                  "Thank you for using EasyInvoice. Your privacy is important to us. "
                  "This Privacy Policy explains how we handle and protect your information.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),
                _sectionTitle("2. No Collection of Personal Data"),
                _paragraph(
                  "EasyInvoice does not collect, store, transmit, or share any personal data "
                  "on external servers or cloud databases.",
                  color: colors.textPrimary,
                ),
                _paragraph(
                  "All the data you enter—such as invoice details, customer information, or templates—"
                  "is stored locally on your device only.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),
                _sectionTitle("3. Biometric Authentication (Optional)"),
                _paragraph(
                  "This app includes optional security features ('App Lock' and 'Smart Lock') that use the device's native biometric authentication (Fingerprint or Face ID).",
                  color: colors.textPrimary,
                ),
                _paragraph(
                  "• Processing: All biometric authentication is handled entirely by the Android/iOS operating system.",
                  color: colors.textPrimary,
                ),
                _paragraph(
                  "• No Storage: We do not collect, store, or transmit your biometric data. The app only receives a 'Success' or 'Failure' signal from the device to allow access.",
                  color: colors.textPrimary,
                ),
                _paragraph(
                  "You can enable or disable these features at any time in the app Settings.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),
                _sectionTitle("4. Local Device Storage"),
                _paragraph(
                  "Your data stays on your phone using secure local storage (SharedPreferences / local files). "
                  "We cannot access, view, or recover your information.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),
                _sectionTitle("5. Data Deletion"),
                _paragraph(
                  "When you uninstall the app or clear its storage, all data is permanently deleted. "
                  "We do not keep any backups.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),
                _sectionTitle("6. Permissions Used"),
                _paragraph(
                  "EasyInvoice may request the following permissions solely for app functionality:",
                  color: colors.textPrimary,
                ),
                _bullet(
                  "Storage – Used only to save invoices/screenshots on your device.",
                  color: colors.textPrimary,
                ),
                _bullet(
                  "Biometrics – Used securely to verify your identity for App Lock features.",
                  color: colors.textPrimary,
                ),
                _bullet(
                  "Internet – Used primarily to check for App Updates via Google Play Services.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),
                _sectionTitle("7. No Tracking or Analytics"),
                _paragraph(
                  "EasyInvoice does not use analytics tools, tracking SDKs, advertising IDs, or cookies for marketing purposes.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),

                _sectionTitle("8. Third-Party Services"),
                _paragraph(
                  "While the app itself does not collect personal data, it utilizes Google Play Services to provide essential functionality. By using the app, you acknowledge that Google may collect data (such as device information and app usage statistics) in accordance with their privacy policy.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 8),
                _bullet(
                  "In-App Updates: We use Google Play Services to check if a newer version of the app is available to ensure you have the latest security patches and features.",
                  color: colors.textPrimary,
                ),
                _bullet(
                  "In-App Reviews: We use Google Play Services to allow you to rate the app directly within the application. No personal identifiable information is stored by us during this process.",
                  color: colors.textPrimary,
                ),

                const SizedBox(height: 20),
                _sectionTitle("9. Children's Privacy"),
                _paragraph(
                  "EasyInvoice does not knowingly collect personal data from children under 13. "
                  "Since no online data collection occurs, the app remains safe for all age groups.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),
                _sectionTitle("10. Changes to This Policy"),
                _paragraph(
                  "We may update this Privacy Policy if required for app improvements or legal compliance. "
                  "Any changes will be reflected here.",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 20),
                _sectionTitle("11. Contact Us"),
                _paragraph(
                  "If you have any questions about this Privacy Policy, you can contact us at:",
                  color: colors.textPrimary,
                ),
                _paragraph(
                  "📧 Email: support.farhanappdev@gmail.com",
                  color: colors.textPrimary,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String text, {Color? color}) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      height: 1.3,
      color: color ?? Colors.black87,
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

  Widget _paragraph(String text, {Color? color}) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        height: 1.55,
        color: color ?? Colors.black87,
      ),
    ),
  );

  Widget _bullet(String text, {Color? color}) => Padding(
    padding: const EdgeInsets.only(left: 8, top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("•  ", style: TextStyle(color: color)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              height: 1.55,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
