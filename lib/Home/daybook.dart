import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';

enum DayBookFilter { today, weekly, monthly, all }

class DayBookPage extends StatefulWidget {
  const DayBookPage({super.key});

  @override
  State<DayBookPage> createState() => _DayBookPageState();
}

class _DayBookPageState extends State<DayBookPage>
    with SingleTickerProviderStateMixin {
  // Data State
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = true;
  String _currencySymbol = '\$';

  // Stats
  double totalRevenue = 0;
  double totalCost = 0;
  double totalProfit = 0;
  double profitPercentage = 0;

  // Filter State
  DayBookFilter _selectedFilter = DayBookFilter.today;

  // Animation
  late AnimationController _animController;

  // Modern Palette (Primary colors - these stay the same)
  final Color _primary = const Color(0xFF2563EB);
  final Color _secondary = const Color(0xFF2563EB);
  final Color _green = const Color(0xFF10B981);
  final Color _red = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    // Load Currency
    _currencySymbol = prefs.getString('currency_symbol') ?? '\$';

    // Load History
    final list = prefs.getStringList("invoice_history") ?? [];
    List<Map<String, dynamic>> filteredList = [];

    double rev = 0;
    double cost = 0;

    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    DateTime startOfMonth = DateTime(now.year, now.month, 1);

    for (var s in list) {
      try {
        final inv = jsonDecode(s);

        // 1. Parse Dates
        DateTime invDate;
        if (inv['savedAt'] != null) {
          invDate = DateTime.parse(inv['savedAt']);
        } else {
          try {
            List<String> parts = inv['invoiceDate'].toString().split('/');
            invDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          } catch (e) {
            invDate = DateTime.now();
          }
        }

        // 2. Filter Logic
        bool include = false;
        switch (_selectedFilter) {
          case DayBookFilter.today:
            include = invDate.isAfter(startOfToday);
            break;
          case DayBookFilter.weekly:
            include = invDate.isAfter(startOfWeek);
            break;
          case DayBookFilter.monthly:
            include = invDate.isAfter(startOfMonth);
            break;
          case DayBookFilter.all:
            include = true;
            break;
        }

        if (include) {
          // 3. Calculations
          double gTotal = double.tryParse(inv['grandTotal'].toString()) ?? 0.0;

          double invCost = 0;
          if (inv['items'] != null) {
            for (var item in inv['items']) {
              int qty = int.tryParse(item['qty'].toString()) ?? 1;
              // 🟢 FETCH THE HIDDEN PURCHASE PRICE
              double pPrice =
                  double.tryParse(item['purchasePrice']?.toString() ?? '0') ??
                  0.0;
              invCost += (qty * pPrice);
            }
          }

          // Store calculations in map for display in list
          inv['calculatedCost'] = invCost;
          inv['calculatedProfit'] = gTotal - invCost;

          rev += gTotal;
          cost += invCost;

          filteredList.add(inv);
        }
      } catch (_) {}
    }

    // Sort: Newest first
    filteredList.sort((a, b) {
      String dateA = a['savedAt'] ?? "";
      String dateB = b['savedAt'] ?? "";
      return dateB.compareTo(dateA);
    });

    setState(() {
      _invoices = filteredList;
      totalRevenue = rev;
      totalCost = cost;
      totalProfit = rev - cost;
      profitPercentage = (rev > 0) ? (totalProfit / rev) * 100 : 0.0;
      _loading = false;
    });

    _animController.forward(from: 0.0);
  }

  void _changeFilter(DayBookFilter filter) {
    setState(() => _selectedFilter = filter);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "DayBook & Profits",
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: _secondary))
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideScreen ? 1000 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      // 1. FILTER TABS
                      _buildFilterTabs(colors),

                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadData,
                          color: _secondary,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 2. SUMMARY CARD
                                _buildSummaryCard(),

                                const SizedBox(height: 24),

                                // 3. LIST HEADER
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Transactions (${_invoices.length})",
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.sort_rounded,
                                      color: colors.icon,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // 4. TRANSACTION LIST
                                _buildTransactionList(colors),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildFilterTabs(AppColors colors) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterPill("Today", DayBookFilter.today, colors),
          const SizedBox(width: 12),
          _filterPill("Weekly", DayBookFilter.weekly, colors),
          const SizedBox(width: 12),
          _filterPill("Monthly", DayBookFilter.monthly, colors),
          const SizedBox(width: 12),
          _filterPill("All Time", DayBookFilter.all, colors),
        ],
      ),
    );
  }

  Widget _filterPill(String text, DayBookFilter filter, AppColors colors) {
    bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _changeFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? _secondary : colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _secondary : colors.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _secondary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "NET PROFIT",
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // FIX: Flexible/FittedBox prevents overflow on large numbers
          FittedBox(
            fit: BoxFit.scaleDown,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: totalProfit),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutExpo,
              builder: (context, val, child) {
                return Text(
                  "$_currencySymbol${val.toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  totalProfit >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: totalProfit >= 0 ? _green : _red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "${profitPercentage.toStringAsFixed(1)}% Margin",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _miniStatItem(
                  "Revenue",
                  totalRevenue,
                  Icons.arrow_downward_rounded,
                  Colors.blue.shade300,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _miniStatItem(
                  "Cost",
                  totalCost,
                  Icons.arrow_upward_rounded,
                  Colors.orange.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatItem(
    String label,
    double val,
    IconData icon,
    Color accentColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // FIX: FittedBox ensures large numbers shrink instead of overflow
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "$_currencySymbol${val.toStringAsFixed(2)}",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(AppColors colors) {
    if (_invoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded, size: 64, color: colors.icon),
              const SizedBox(height: 16),
              Text(
                "No transactions found",
                style: GoogleFonts.inter(
                  color: colors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final profit = inv['calculatedProfit'] ?? 0.0;
        final revenue = double.tryParse(inv['grandTotal'].toString()) ?? 0.0;
        final isProfit = profit >= 0;

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final double slideVal = (1 - _animController.value) * 30;
            return Transform.translate(
              offset: Offset(0, slideVal + (index * 5).clamp(0, 50)),
              child: Opacity(
                opacity: _animController.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv['customerName']?.toString().isNotEmpty == true
                            ? inv['customerName']
                            : 'Unknown Customer',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              inv['invoiceId'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            inv['invoiceDate'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right: Money
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Profit",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // FIX: FittedBox protects layout from large numbers
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${isProfit ? '+' : ''}$_currencySymbol${profit.toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isProfit ? _green : _red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Rev: $_currencySymbol${revenue.toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
