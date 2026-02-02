import 'package:EasyInvoice/Drawer/about.dart';
import 'package:EasyInvoice/Drawer/privacy_page.dart';
import 'package:EasyInvoice/Drawer/request_feature_page.dart';
import 'package:EasyInvoice/Drawer/settings.dart';
import 'package:EasyInvoice/Drawer/support.dart';
import 'package:EasyInvoice/Drawer/terms&condition.dart' show TermsPage;
import 'package:EasyInvoice/Provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLegalDrawer extends StatelessWidget {
  const AppLegalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Menu Data
    final menuItems = [
      _MenuItem(
        Icons.settings_rounded,
        "Settings",
        "Preferences & Account",
        const SettingsPage(),
      ),
      _MenuItem(
        Icons.lightbulb_outline_rounded,
        "Request a Feature",
        "Share your ideas with us",
        const RequestFeaturePage(),
      ),
      _MenuItem(
        Icons.privacy_tip_rounded,
        "Privacy Policy",
        "Data protection",
        const PrivacyPolicyPage(),
      ),
      _MenuItem(
        Icons.description_rounded,
        "Terms & Conditions",
        "Usage rules",
        const TermsPage(),
      ),
      _MenuItem(
        Icons.info_rounded,
        "About App",
        "Version 1.3.0",
        const AboutPage(),
      ),
      _MenuItem(
        Icons.support_agent_rounded,
        "Contact Support",
        "We are here to help",
        const SupportPage(),
      ),
    ];

    final colors = AppColors(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 600 ? 380.0 : screenWidth * 0.85;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: drawerWidth,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(10, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(colors),

              const SizedBox(height: 10),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 20),

              // 2. Menu List with Animation
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: menuItems.length,
                  separatorBuilder: (c, i) =>
                      const SizedBox(height: 12), // Increased spacing
                  itemBuilder: (context, index) {
                    return _AnimatedMenuTile(
                      index: index,
                      item: menuItems[index],
                      colors: colors,
                    );
                  },
                ),
              ),

              // 3. Footer
              _buildFooter(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Row(
        children: [
          // Logo Container
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF2563EB), // Brand Blue
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EasyInvoice",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Light Blue
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Text(
                    "PROFESSIONAL",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB), // Brand Blue
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "Designed by AppXplora",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "Close Menu",
                  style: GoogleFonts.inter(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Data Model ---
class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;
  _MenuItem(this.icon, this.title, this.subtitle, this.page);
}

// --- The Animated Menu Tile ---
class _AnimatedMenuTile extends StatefulWidget {
  final int index;
  final _MenuItem item;
  final AppColors colors;

  const _AnimatedMenuTile({
    required this.index,
    required this.item,
    required this.colors,
  });

  @override
  State<_AnimatedMenuTile> createState() => _AnimatedMenuTileState();
}

class _AnimatedMenuTileState extends State<_AnimatedMenuTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Staggered Entry Animation
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-20 * (1 - value), 0),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          Future.delayed(const Duration(milliseconds: 150), () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => widget.item.page),
            );
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isPressed ? widget.colors.background : widget.colors.card,
            borderRadius: BorderRadius.circular(16),
            // 🟢 Added Border Here
            border: Border.all(color: widget.colors.border, width: 1),
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.colors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.colors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: widget.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: widget.colors.border,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
