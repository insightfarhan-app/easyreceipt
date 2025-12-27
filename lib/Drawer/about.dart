import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "About EasyInvoice",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header("What is EasyInvoice?"),
            _text(
              "EasyInvoice is a professional and user-friendly mobile application designed to help individuals, "
              "small businesses, freelancers, and shop owners create clean, accurate, and customizable invoices within seconds. "
              "The app offers modern templates, automatic calculations, tax support, invoice history, reports, and local storage — "
              "all without requiring internet or an online account.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("Why EasyInvoice?"),
            _bullets([
              "Simple and fast invoice creation",
              "Works completely offline — no account needed",
              "Invoices stored locally on your device",
              "Professional templates for all business types",
              "Detailed history and reporting",
              "Customizable branding: logo, colors, business details",
              "One-tap PDF export and sharing",
              "Clean UI designed for speed and accuracy",
            ]),

            const SizedBox(height: 25),

            _sectionTitle("100% Offline & Secure"),
            _text(
              "Your privacy is our priority. EasyInvoice does not send or store any data on external servers. "
              "All information — including customers, items, invoices, and templates — stays safely on your device only. "
              "You are always in full control of your data.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("Our Mission"),
            _text(
              "Our mission is to empower small business owners and freelancers with a powerful yet simple tool to manage "
              "their day-to-day invoicing without complexity or hidden costs. "
              "We aim to provide professional-grade features normally found in expensive software — but in an easy, offline, mobile experience.",
            ),

            const SizedBox(height: 25),

            _sectionTitle("Who Can Use EasyInvoice?"),
            _bullets([
              "Shop owners",
              "Freelancers",
              "Wholesalers & retailers",
              "Service providers",
              "Entrepreneurs",
              "Self-employed workers",
              "Students and personal invoice needs",
            ]),

            const SizedBox(height: 25),

            _sectionTitle("Developer Information"),
            _text(
              "EasyInvoice is built with love, care, and precision. Every feature is designed to improve your workflow "
              "and reduce the time required to create an invoice.",
            ),
            const SizedBox(height: 8),
            _textBold("Developer: EasyInvoice Team"),
            _text("Country: Pakistan"),

            const SizedBox(height: 25),

            _sectionTitle("Contact & Support"),
            _text(
              "For feedback, suggestions, or support, feel free to reach out to us:",
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("•  ", style: TextStyle(fontSize: 22)),
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
