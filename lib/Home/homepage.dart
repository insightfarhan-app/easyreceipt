import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:EasyInvoice/Drawer/app_drawer.dart';
import 'package:EasyInvoice/Home/daybook.dart';
import 'package:EasyInvoice/Home/invoice_form_page.dart';
import 'package:EasyInvoice/Home/invoice_history.dart';
import 'package:EasyInvoice/Quotation/quotation_homepage.dart';
import 'package:EasyInvoice/Home/invoice_report.dart';
import 'package:EasyInvoice/Home/invoice_template_page.dart';
import 'package:EasyInvoice/Home/sales_graph.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';
import 'package:EasyInvoice/Services/purchase_history.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- COLORS ---
  final Color _primaryColor = const Color(0xFF2563EB); // Royal Blue

  // --- STATE VARIABLES ---
  bool _isLoading = true;
  bool _hasData = false;
  double _totalRevenue = 0.0;
  int _totalInvoicesCount = 0;
  int _cashInvoicesCount = 0;
  int _creditInvoicesCount = 0;
  double _todaySales = 0.0;
  double _yesterdaySales = 0.0;
  List<double> _weeklySales = [0, 0, 0, 0, 0, 0, 0];
  String? _companyLogoPath;

  // --- TAGLINE ANIMATION ---
  int _currentTaglineIndex = 0;
  final List<String> _taglines = [
    "Create professional invoices in seconds",
    "Track your business growth effortlessly",
    "Send quotations that win clients",
    "Generate PDF receipts instantly",
    "Manage customers & transactions easily",
    "Beautiful templates, zero hassle",
    "Your pocket-friendly billing partner",
    "Smart billing for modern businesses",
    "Less paperwork. More productivity",
    "Protect your data with smart app lock",
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _checkForUpdate();
    _startTaglineAnimation();

    // Smart Review Logic
    Future.delayed(const Duration(seconds: 6), () {
      _checkAndRequestReview();
    });

    // Show theme selection modal on first launch (after widget is built)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowThemeModal();
    });
  }

  Future<void> _checkAndShowThemeModal() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSelectedTheme = prefs.getBool('theme_selected') ?? false;

    if (!hasSelectedTheme && mounted) {
      // Show modal after a short delay to allow page to render
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showThemeSelectionModal();
      }
    }
  }

  void _showThemeSelectionModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Theme Selection',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10 * animation.value,
              sigmaY: 10 * animation.value,
            ),
            child: Container(
              color: Colors.black.withOpacity(0.3 * animation.value),
              child: Center(
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: _buildThemeSelectionCard(dialogContext),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startTaglineAnimation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentTaglineIndex = (_currentTaglineIndex + 1) % _taglines.length;
        });
        _startTaglineAnimation();
      }
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  Future<void> _checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    final InAppReview inAppReview = InAppReview.instance;
    bool isRated = prefs.getBool('is_rated') ?? false;
    if (isRated) return;

    int launchCount = prefs.getInt('launch_count') ?? 0;
    launchCount++;
    await prefs.setInt('launch_count', launchCount);

    if (launchCount == 5 || launchCount == 20 || launchCount == 50) {
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }

  Future<void> _refresh() async {
    await _loadDashboardData();
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final logo = prefs.getString('company_logo');
    final list = await PurchaseHistoryService.getRawHistory();

    if (list.isEmpty) {
      if (mounted) {
        setState(() {
          _companyLogoPath = logo;
          _hasData = false;
          _isLoading = false;
        });
      }
      return;
    }

    double totalRev = 0.0;
    int totalCount = 0;
    int cashCount = 0;
    int creditCount = 0;
    double today = 0.0;
    double yesterday = 0.0;
    Map<int, double> last7DaysMap = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

    final now = DateTime.now();
    final yest = now.subtract(const Duration(days: 1));

    for (var item in list) {
      try {
        final Map<String, dynamic> data = jsonDecode(item);
        double amount = double.tryParse(data['grandTotal'].toString()) ?? 0.0;

        totalRev += amount;
        totalCount++;

        String type =
            data['invoiceType'] ??
            (data['status'] == 'Paid' ? 'Cash' : 'Credit');
        if (type == 'Cash') {
          cashCount++;
        } else {
          creditCount++;
        }

        DateTime? invDate =
            DateTime.tryParse(data['invoiceDate'] ?? '') ??
            DateTime.tryParse(data['savedAt'] ?? '');

        if (invDate != null) {
          if (invDate.year == now.year &&
              invDate.month == now.month &&
              invDate.day == now.day) {
            today += amount;
          }
          if (invDate.year == yest.year &&
              invDate.month == yest.month &&
              invDate.day == yest.day) {
            yesterday += amount;
          }

          final difference = DateTime(now.year, now.month, now.day)
              .difference(DateTime(invDate.year, invDate.month, invDate.day))
              .inDays;

          if (difference >= 0 && difference < 7) {
            last7DaysMap[difference] = (last7DaysMap[difference] ?? 0) + amount;
          }
        }
      } catch (e) {}
    }

    List<double> graphData = [];
    for (int i = 6; i >= 0; i--) {
      graphData.add(last7DaysMap[i] ?? 0.0);
    }

    if (mounted) {
      setState(() {
        _companyLogoPath = logo;
        _hasData = true;
        _totalRevenue = totalRev;
        _totalInvoicesCount = totalCount;
        _cashInvoicesCount = cashCount;
        _creditInvoicesCount = creditCount;
        _todaySales = today;
        _yesterdaySales = yesterday;
        _weeklySales = graphData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppLegalDrawer(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- CUSTOM APP BAR ---
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false, // Removed Default Drawer Icon
            backgroundColor: colors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: colors.background),
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              title: Row(
                children: [
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.card,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu_rounded,
                          color: colors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "EasyInvoice",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_companyLogoPath != null)
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: kIsWeb
                          ? NetworkImage(_companyLogoPath!)
                          : FileImage(File(_companyLogoPath!)) as ImageProvider,
                    )
                  else
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: _primaryColor, size: 20),
                    ),
                ],
              ),
            ),
          ),

          // --- CONTENT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DASHBOARD CARD
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildModernDashboard(),

                  const SizedBox(height: 24),

                  // 2. MAIN ACTION (Solid Dark)
                  _buildCreateInvoiceButton(),

                  const SizedBox(height: 12),

                  // 2.1 QUOTATION BUTTON
                  _buildQuotationButton(),

                  const SizedBox(height: 24),

                  Text(
                    "Quick Actions",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. GRID MENU (White with Colored Borders)
                  Row(
                    children: [
                      _buildGridCard(
                        context: context,
                        title: "Edit\nTemplate",
                        icon: Icons.edit_note_rounded,
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceTemplatePage(
                              invoiceData: {'customerName': '', 'items': []},
                            ),
                          ),
                        ).then((_) => _refresh()),
                      ),
                      const SizedBox(width: 12),
                      _buildGridCard(
                        context: context,
                        title: "Sales\nReports",
                        icon: Icons.bar_chart_rounded,
                        color: Colors.purpleAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InvoiceReport()),
                        ).then((_) => _refresh()),
                      ),
                      const SizedBox(width: 12),
                      _buildGridCard(
                        context: context,
                        title: "All\nHistory",
                        icon: Icons.history_rounded,
                        color: Colors.teal,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvoiceHistory(),
                          ),
                        ).then((_) => _refresh()),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. DAYBOOK CARD (White with Pink Border)
                  _buildWideCard(
                    context: context,
                    title: "DayBook",
                    subtitle: "Daily transaction logs",
                    icon: Icons.book_rounded,
                    color: Colors.pinkAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DayBookPage()),
                    ).then((_) => _refresh()),
                  ),

                  const SizedBox(height: 24),

                  // 5. GRAPH
                  if (_hasData) ...[
                    Text(
                      "Weekly Performance",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SalesGraph(data: _weeklySales),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // 6. WHY USE EASYINVOICE
                  Text(
                    "Why EasyInvoice?",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Feature Tiles
                  Row(
                    children: [
                      _buildFeatureTile(
                        context: context,
                        icon: Icons.flash_on_rounded,
                        title: "Fast",
                        subtitle: "Instant PDFs",
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      _buildFeatureTile(
                        context: context,
                        icon: Icons.lock_rounded,
                        title: "Secure",
                        subtitle: "Local Data",
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildFeatureTile(
                        context: context,
                        icon: Icons.star_rounded,
                        title: "Pro",
                        subtitle: "Clean Design",
                        color: Colors.blue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Theme Switcher Card - Beautiful & Animated
                  _buildThemeSwitcherCard(context),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildModernDashboard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "More Than Just Billing!",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _taglines[_currentTaglineIndex],
              key: ValueKey<int>(_currentTaglineIndex),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < _taglines.length; i++)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: _currentTaglineIndex == i ? 20 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentTaglineIndex == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // 🟢 Dark, Professional Create Button (Stays Solid)
  Widget _buildCreateInvoiceButton() {
    final colors = AppColors(context);
    return Material(
      color: colors.isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFF1E293B), // Dark Slate Background
      borderRadius: BorderRadius.circular(24),
      shadowColor: const Color(0xFF1E293B).withOpacity(0.4),
      elevation: 8,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InvoiceFormPage()),
          ).then((_) => _refresh());
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create New Invoice",
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Generate a bill instantly",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationButton() {
    return Material(
      color: _primaryColor,
      borderRadius: BorderRadius.circular(24),
      shadowColor: _primaryColor.withOpacity(0.4),
      elevation: 8,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuotationHomePage()),
          ).then((_) => _refresh());
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.request_quote_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quotation",
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Create & manage quotes",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 White Card with Colored Border
  Widget _buildGridCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = AppColors(context);
    return Expanded(
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 135,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1.5,
              ), // Colored Border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 White Wide Card with Colored Border
  Widget _buildWideCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = AppColors(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1.5,
            ), // Colored Border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.icon,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final colors = AppColors(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitcherCard(BuildContext context) {
    final colors = AppColors(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155).withOpacity(0.5)
                      : const Color(0xFFE2E8F0),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : const Color(0xFF2563EB).withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: isDark ? 0 : 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with icon
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF3B82F6),
                                    const Color(0xFF60A5FA),
                                  ]
                                : [
                                    const Color(0xFF2563EB),
                                    const Color(0xFF3B82F6),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isDark
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFF2563EB))
                                      .withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedRotation(
                          turns: isDark ? 0.5 : 0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          child: Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Theme Preference",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Customize your experience",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Theme Toggle with smooth animation
                  Container(
                    height: 64,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated sliding background
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          alignment: isDark
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.42,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF3B82F6),
                                        const Color(0xFF2563EB),
                                      ]
                                    : [
                                        const Color(0xFFFB923C),
                                        const Color(0xFFF59E0B),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isDark
                                              ? const Color(0xFF3B82F6)
                                              : const Color(0xFFFB923C))
                                          .withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Light and Dark buttons
                        Row(
                          children: [
                            // Light Theme Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  if (isDark) {
                                    await themeProvider.setDarkMode(false);
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: !isDark
                                            ? Colors.white
                                            : colors.textSecondary,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.light_mode_rounded,
                                            size: 20,
                                            color: !isDark
                                                ? Colors.white
                                                : colors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text("Light"),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Dark Theme Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  if (!isDark) {
                                    await themeProvider.setDarkMode(true);
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : colors.textSecondary,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.dark_mode_rounded,
                                            size: 20,
                                            color: isDark
                                                ? Colors.white
                                                : colors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text("Dark"),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Benefits Row with animated icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBenefitChip(
                        icon: Icons.remove_red_eye_outlined,
                        label: "Eye Comfort",
                        colors: colors,
                      ),
                      _buildBenefitChip(
                        icon: Icons.battery_charging_full_rounded,
                        label: isDark ? "Save Battery" : "Bright View",
                        colors: colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitChip({
    required IconData icon,
    required String label,
    required AppColors colors,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.isDark
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.isDark
                    ? const Color(0xFF334155).withOpacity(0.5)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSelectionCard(BuildContext dialogContext) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.90),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    // decoration: BoxDecoration(
                    //   gradient: const LinearGradient(
                    //     colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    //   ),
                    //   borderRadius: BorderRadius.circular(20),
                    //   boxShadow: [
                    //     BoxShadow(
                    //       // color: const Color(0xFF2563EB).withOpacity(0.4),
                    //       blurRadius: 50,
                    //       offset: const Offset(0, 8),
                    //     ),
                    //   ],
                    // ),
                    child: Lottie.asset(
                      'assets/animations/theme.json',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    "Choose Your Theme",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    "Select your preferred theme to get started",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Theme Selection Buttons
                  Row(
                    children: [
                      // Light Theme
                      Expanded(
                        child: _buildThemeOptionCard(
                          icon: Icons.light_mode_rounded,
                          label: "Light",
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFB923C), Color(0xFFF59E0B)],
                          ),
                          onTap: () async {
                            await themeProvider.setDarkMode(false);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('theme_selected', true);
                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Dark Theme
                      Expanded(
                        child: _buildThemeOptionCard(
                          icon: Icons.dark_mode_rounded,
                          label: "Dark",
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          ),
                          onTap: () async {
                            await themeProvider.setDarkMode(true);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('theme_selected', true);
                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Benefits
                  Text(
                    "💡 You can change this anytime from settings",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.85 + (value * 0.15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
