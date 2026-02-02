import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Support & Help",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 800 : double.infinity,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text(
                  "We're Here to Help",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 10),
                _text(
                  colors,
                  "If you have questions, issues, or suggestions, you can reach out anytime. "
                  "Our support team is always ready to help improve your EasyInvoice experience.",
                ),

                const SizedBox(height: 30),

                _sectionTitle("Contact Support"),
                const SizedBox(height: 10),

                _supportCard(
                  colors: colors,
                  icon: Icons.email_outlined,
                  title: "Email Support",
                  subtitle: "Get help or send feedback",
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'farhanappdev@gmail.com',
                      query:
                          'subject=Support Request - EasyReceipt&body=Hello,%0D%0A%0D%0AI need help regarding...',
                    );

                    try {
                      final bool launched = await launchUrl(
                        emailUri,
                        mode: LaunchMode.externalApplication, // IMPORTANT 🔥
                      );

                      if (!launched) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Unable to open email app."),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                ),
                SizedBox(height: 10),

                _supportCard(
                  colors: colors,
                  icon: Icons.bug_report_outlined,
                  title: "Report a Bug",
                  subtitle: "Tell us what's not working",
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'farhanappdev@gmail.com',
                      query: Uri.encodeQueryComponent(
                        "subject=Bug Report - EasyReceipt&"
                        "body=Hello,%0D%0A%0D%0A"
                        "I want to report a bug:%0D%0A"
                        "- Describe what happened:%0D%0A"
                        "- Steps to reproduce:%0D%0A"
                        "- Expected result:%0D%0A"
                        "- Actual result:%0D%0A%0D%0A"
                        "Device Info:%0D%0A"
                        "- App Version: 1.0.0%0D%0A"
                        "- OS: Android%0D%0A"
                        "- Model: Unknown%0D%0A"
                        "%0D%0AThank you!",
                      ),
                    );

                    try {
                      final bool launched = await launchUrl(
                        emailUri,
                        mode: LaunchMode.externalApplication,
                      );

                      if (!launched) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Unable to open email app."),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                ),

                const SizedBox(height: 30),

                _sectionTitle("Frequently Asked Questions"),
                const SizedBox(height: 15),

                _faq(
                  colors,
                  "Does EasyInvoice require internet?",
                  "No. EasyInvoice works completely offline. You can create, save, and manage invoices without internet.",
                ),
                _faq(
                  colors,
                  "Where is my data stored?",
                  "Everything is stored locally on your device. We do not store anything on servers.",
                ),
                _faq(
                  colors,
                  "What happens if I uninstall the app?",
                  "All locally stored invoices and data will be permanently deleted.",
                ),
                _faq(
                  colors,
                  "Can I restore deleted invoices?",
                  "No. Since data is stored offline only, deleted invoices cannot be recovered.",
                ),
                _faq(
                  colors,
                  "Can I export invoices?",
                  "Yes! You can save invoices as PDF or image and share them with customers.",
                ),
                _faq(
                  colors,
                  "What data does the Dashboard cover?",
                  "The dashboard analyzes all your saved invoices to show real-time metrics. It tracks your Total Sales, Total Received Amount, and Outstanding/Pending balances so you know exactly how much money is owed to you.",
                ),
                _faq(
                  colors,
                  "How does the Graph Chart comparison work?",
                  "The graph compares your income trends over specific periods (like Week vs. Month). It visualizes your cash flow peaks and drops, making it easier to see which days or months were most profitable.",
                ),

                const SizedBox(height: 30),

                // TROUBLESHOOTING
                _sectionTitle("Troubleshooting"),
                const SizedBox(height: 15),

                _bulletList(colors, [
                  "Restart the app if the UI freezes.",
                  "Clear app cache if templates don't load.",
                  "Ensure storage permission is granted for saving invoices.",
                  "Re-check invoice fields before saving or exporting.",
                  "Update the app to the latest version for bug fixes.",
                ]),

                const SizedBox(height: 30),

                // FINAL MESSAGE
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF1565C0),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "Thank you for using EasyInvoice! Your feedback helps us make the app faster, easier, and more powerful. "
                    "We are committed to supporting small businesses and freelancers worldwide.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ UI COMPONENTS ------------------

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

  Widget _text(AppColors colors, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _supportCard({
    required AppColors colors,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 28),
            const SizedBox(height: 4),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: colors.icon),
          ],
        ),
      ),
    );
  }

  Widget _faq(AppColors colors, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletList(AppColors colors, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "•  ",
                style: TextStyle(fontSize: 20, color: colors.textPrimary),
              ),
              Expanded(
                child: Text(
                  e,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
