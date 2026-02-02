import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:EasyInvoice/Home/compare_report.dart';
import 'package:EasyInvoice/Home/report_generator.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

enum ReportRange { daily, weekly, monthly, yearly, overall }

class InvoiceReport extends StatefulWidget {
  const InvoiceReport({super.key});

  @override
  State<InvoiceReport> createState() => _InvoiceReportState();
}

class _InvoiceReportState extends State<InvoiceReport>
    with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  List<Map<String, dynamic>> _allInvoices = [];
  List<Map<String, dynamic>> _filteredInvoices = [];

  bool _loading = true;
  ReportRange _range = ReportRange.daily;

  // --- STATS VARIABLES ---
  int totalInvoices = 0;
  double totalSales = 0;
  double totalTax = 0;
  int cashInvoices = 0;
  double cashSales = 0;
  int totalCreditInvoices = 0;
  double totalCreditSales = 0;
  int creditPaidInvoices = 0;
  double creditPaidSales = 0;
  int creditUnpaidInvoices = 0;
  double creditUnpaidSales = 0;

  List<String> chartLabels = [];
  List<double> chartValues = [];

  late AnimationController _animCtrl;

  // --- COLORS (Primary accent only - others from theme) ---
  final Color _primaryColor = const Color(0xFF2563EB); // Royal Blue

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 1,
    );
    _loadInvoices();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('invoice_history') ?? [];

    final parsed = <Map<String, dynamic>>[];

    for (final s in list) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          decoded['status'] ??= 'Unpaid';
          decoded['invoiceType'] ??= 'Credit';
          decoded['grandTotal'] ??= 0;
          decoded['tax'] ??= 0;

          if (decoded['savedAt'] == null && decoded['invoiceDate'] == null) {
            decoded['savedAt'] = DateTime.now().toIso8601String();
          }
          parsed.add(decoded);
        }
      } catch (_) {}
    }

    setState(() {
      _allInvoices = parsed;
      _loading = false;
    });

    _recompute();
    _animCtrl.forward();
  }

  DateTime _parseDate(Map<String, dynamic> inv) {
    try {
      if (inv['savedAt'] != null) return DateTime.parse(inv['savedAt']);
      if (inv['invoiceDate'] != null) return DateTime.parse(inv['invoiceDate']);
      return DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  void _recompute() {
    final now = DateTime.now();
    List<Map<String, dynamic>> filtered = [];

    DateTime start;
    DateTime end = now;

    switch (_range) {
      case ReportRange.daily:
        start = DateTime(now.year, now.month, now.day);
        break;
      case ReportRange.weekly:
        start = now.subtract(const Duration(days: 7));
        break;
      case ReportRange.monthly:
        start = now.subtract(const Duration(days: 30));
        break;
      case ReportRange.yearly:
        start = now.subtract(const Duration(days: 365));
        break;
      case ReportRange.overall:
        start = DateTime(1970);
        break;
    }

    for (final inv in _allInvoices) {
      final saved = _parseDate(inv);
      if (!saved.isBefore(start) &&
          !saved.isAfter(end.add(const Duration(seconds: 1)))) {
        filtered.add(inv);
      }
    }

    // Reset counters
    int tCount = 0;
    double tSales = 0;
    double tTax = 0;

    int cCount = 0;
    double cSales = 0;
    int tcCount = 0;
    double tcSales = 0;
    int cpCount = 0;
    double cpSales = 0;
    int cupCount = 0;
    double cupSales = 0;

    for (final inv in filtered) {
      double amount = 0.0;
      if (inv['grandTotal'] != null) {
        amount = double.tryParse(inv['grandTotal'].toString()) ?? 0.0;
      }

      double tax = 0.0;
      if (inv['tax'] != null) {
        tax = double.tryParse(inv['tax'].toString()) ?? 0.0;
      }

      String type = (inv['invoiceType'] ?? 'Credit').toString();
      String status = (inv['status'] ?? 'Unpaid').toString();

      tCount++;
      tSales += amount;
      tTax += tax;

      if (type == 'Cash') {
        cCount++;
        cSales += amount;
      } else {
        tcCount++;
        tcSales += amount;

        if (status == 'Paid') {
          cpCount++;
          cpSales += amount;
        } else {
          cupCount++;
          cupSales += amount;
        }
      }
    }

    // Chart Data Generation logic remains same...
    List<String> labels = [];
    List<double> values = [];

    // (Simplified chart logic for brevity - keeping your exact logic)
    if (_range == ReportRange.daily) {
      for (int i = 0; i <= 20; i += 4) {
        labels.add("$i:00");
        double sum = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv);
          if (saved.hour >= i && saved.hour < i + 4) {
            sum += double.tryParse(inv['grandTotal'].toString()) ?? 0.0;
          }
        }
        values.add(sum);
      }
    } else if (_range == ReportRange.weekly) {
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        labels.add("${d.day}/${d.month}");
        double sum = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv);
          if (saved.day == d.day &&
              saved.month == d.month &&
              saved.year == d.year) {
            sum += double.tryParse(inv['grandTotal'].toString()) ?? 0.0;
          }
        }
        values.add(sum);
      }
    } else if (_range == ReportRange.monthly) {
      for (int i = 3; i >= 0; i--) {
        final wStart = now.subtract(Duration(days: (i * 7) + 6));
        final wEnd = now.subtract(Duration(days: i * 7));
        labels.add("W${4 - i}");
        double sum = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv);
          if (saved.isAfter(wStart.subtract(const Duration(seconds: 1))) &&
              saved.isBefore(wEnd.add(const Duration(days: 1)))) {
            sum += double.tryParse(inv['grandTotal'].toString()) ?? 0.0;
          }
        }
        values.add(sum);
      }
    } else if (_range == ReportRange.yearly) {
      for (int i = 11; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        labels.add("${d.month}/${d.year % 100}");
        double sum = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv);
          if (saved.month == d.month && saved.year == d.year) {
            sum += double.tryParse(inv['grandTotal'].toString()) ?? 0.0;
          }
        }
        values.add(sum);
      }
    } else {
      for (int i = 4; i >= 0; i--) {
        int y = now.year - i;
        labels.add("$y");
        double sum = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv);
          if (saved.year == y) {
            sum += double.tryParse(inv['grandTotal'].toString()) ?? 0.0;
          }
        }
        values.add(sum);
      }
    }

    setState(() {
      _filteredInvoices = filtered;
      totalInvoices = tCount;
      totalSales = tSales;
      totalTax = tTax;
      cashInvoices = cCount;
      cashSales = cSales;
      totalCreditInvoices = tcCount;
      totalCreditSales = tcSales;
      creditPaidInvoices = cpCount;
      creditPaidSales = cpSales;
      creditUnpaidInvoices = cupCount;
      creditUnpaidSales = cupSales;
      chartLabels = labels;
      chartValues = values;
    });
  }

  void _onRangeChanged(ReportRange r) {
    setState(() => _range = r);
    _recompute();
  }

  String _getRangeString() {
    switch (_range) {
      case ReportRange.daily:
        return "Daily Report (Today)";
      case ReportRange.weekly:
        return "Weekly Report (Last 7 Days)";
      case ReportRange.monthly:
        return "Monthly Report (Last 30 Days)";
      case ReportRange.yearly:
        return "Yearly Report (Last 365 Days)";
      case ReportRange.overall:
        return "Overall Report";
    }
  }

  Future<void> _handleShare() async {
    if (_filteredInvoices.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No data to share")));
      return;
    }

    try {
      final cashBills = _filteredInvoices
          .where((i) => (i['invoiceType'] ?? 'Credit') == 'Cash')
          .toList();
      final creditBills = _filteredInvoices
          .where((i) => (i['invoiceType'] ?? 'Credit') != 'Cash')
          .toList();
      final sortedInvoices = [...cashBills, ...creditBills];

      final bytes = await ReportGenerator.generateBytes(
        invoices: sortedInvoices,
        rangeName: _getRangeString(),
        totalSales: totalSales,
        totalTax: totalTax,
        cashSales: cashSales,
        creditSales: totalCreditSales,
      );

      final directory = await getTemporaryDirectory();
      final fileName =
          "Sales_Report_${_getRangeString().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "Here is the ${_getRangeString()} from EasyInvoice.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error generating report: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePrint() async {
    if (_filteredInvoices.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No data to print")));
      return;
    }

    final cashBills = _filteredInvoices
        .where((i) => (i['invoiceType'] ?? 'Credit') == 'Cash')
        .toList();
    final creditBills = _filteredInvoices
        .where((i) => (i['invoiceType'] ?? 'Credit') != 'Cash')
        .toList();
    final sortedInvoices = [...cashBills, ...creditBills];

    await ReportGenerator.printReport(
      invoices: sortedInvoices,
      rangeName: _getRangeString(),
      totalSales: totalSales,
      totalTax: totalTax,
      cashSales: cashSales,
      creditSales: totalCreditSales,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.background,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Invoice Reports",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadInvoices,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 1200 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _whiteSummaryCard(),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(child: _rangeSelector(colors)),
                              const SizedBox(width: 12),
                              _actionButton(colors),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Text(
                            "Detailed Statistics",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _whiteKpiCard(
                                colors,
                                "Total Invoices",
                                "$totalInvoices",
                                width: 100,
                              ),
                              _whiteKpiCard(
                                colors,
                                "Total Sales",
                                totalSales.toStringAsFixed(2),
                                width: 155,
                              ),

                              _whiteKpiCard(
                                colors,
                                "Cash Invoices",
                                "$cashInvoices",
                                isGreen: true,
                                width: 100,
                              ),
                              _whiteKpiCard(
                                colors,
                                "Cash Sales",
                                cashSales.toStringAsFixed(2),
                                isGreen: true,
                                width: 155,
                              ),

                              _whiteKpiCard(
                                colors,
                                "Total Credit Inv",
                                "$totalCreditInvoices",
                                width: 100,
                              ),
                              _whiteKpiCard(
                                colors,
                                "Total Credit Sales",
                                totalCreditSales.toStringAsFixed(2),
                                width: 155,
                              ),

                              _whiteKpiCard(
                                colors,
                                "Credit Paid Inv",
                                "$creditPaidInvoices",
                                isBlue: true,
                                width: 100,
                              ),
                              _whiteKpiCard(
                                colors,
                                "Credit Paid Sales",
                                creditPaidSales.toStringAsFixed(2),
                                isBlue: true,
                                width: 155,
                              ),

                              _whiteKpiCard(
                                colors,
                                "Cr. Unpaid Inv",
                                "$creditUnpaidInvoices",
                                isOrange: true,
                                width: 100,
                              ),
                              _whiteKpiCard(
                                colors,
                                "Cr. Unpaid Sales",
                                creditUnpaidSales.toStringAsFixed(2),
                                isOrange: true,
                                width: 155,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          _chartCard(colors),
                          const SizedBox(height: 24),
                          Text(
                            "Recent invoices",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _recentListTilePreview(colors),

                          const SizedBox(height: 40),

                          Column(
                            children: [
                              SizedBox(
                                height: 56,
                                width: double.infinity,
                                child: _reportActionButton(
                                  icon: Icons.share_rounded,
                                  label: "Share Report",
                                  color: const Color(0xFF2E7D32),
                                  onTap: _handleShare,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 56,
                                width: double.infinity,
                                child: _reportActionButton(
                                  icon: Icons.print_rounded,
                                  label: "Print Report",
                                  color: const Color(0xFFE65100),
                                  onTap: _handlePrint,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _reportActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _whiteSummaryCard() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
            Text(
              "Report Overview (${_range.name.toUpperCase()})",
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              totalSales.toStringAsFixed(2),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$totalInvoices invoices generated",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeSelector(AppColors colors) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportRange>(
          value: _range,
          isExpanded: true,
          dropdownColor: colors.card,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textPrimary,
          ),
          items: const [
            DropdownMenuItem(
              value: ReportRange.daily,
              child: Text("Daily Report"),
            ),
            DropdownMenuItem(
              value: ReportRange.weekly,
              child: Text("Weekly Report"),
            ),
            DropdownMenuItem(
              value: ReportRange.monthly,
              child: Text("Monthly Report"),
            ),
            DropdownMenuItem(
              value: ReportRange.yearly,
              child: Text("Yearly Report"),
            ),
            DropdownMenuItem(
              value: ReportRange.overall,
              child: Text("Overall Report"),
            ),
          ],
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (v) {
            if (v != null) _onRangeChanged(v);
          },
        ),
      ),
    );
  }

  Widget _whiteKpiCard(
    AppColors colors,
    String title,
    String value, {
    bool isGreen = false,
    bool isOrange = false,
    bool isBlue = false,
    double? width,
  }) {
    Color valColor = colors.textPrimary;
    if (isGreen) valColor = Colors.green[700]!;
    if (isOrange) valColor = Colors.orange[800]!;
    if (isBlue) valColor = Colors.blue[700]!;

    return Container(
      width: width ?? 155,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(AppColors colors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompareReportPage()),
        );
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: colors.textPrimary, // Dark button
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.compare_arrows_rounded, color: colors.card, size: 24),
      ),
    );
  }

  Widget _chartCard(AppColors colors) {
    if (chartValues.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        height: 220,
        child: Center(
          child: Text(
            "No data for this range",
            style: GoogleFonts.inter(color: colors.textSecondary),
          ),
        ),
      );
    }

    double maxY = chartValues.reduce(max);
    if (maxY == 0) maxY = 100;

    int ticks = 5;
    double interval = (maxY / ticks).ceilToDouble();
    if (interval == 0) interval = 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sales chart",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (idx, meta) {
                        final i = idx.toInt();
                        final label = (i < chartLabels.length)
                            ? chartLabels[i]
                            : '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: colors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(chartValues.length, (i) {
                  final v = chartValues[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        width: 12,
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentListTilePreview(AppColors colors) {
    final sorted = List<Map<String, dynamic>>.from(_allInvoices);
    sorted.sort((a, b) {
      final da = _parseDate(a);
      final db = _parseDate(b);
      return db.compareTo(da);
    });

    final show = sorted.take(5).toList();

    if (show.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "No invoices yet",
            style: GoogleFonts.inter(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: show.map((inv) {
        final id = inv['invoiceId'] ?? 'INV-UNKNOWN';
        final customer = inv['customerName'] ?? 'Unknown';
        final total = (inv['grandTotal'] is num)
            ? (inv['grandTotal'] as num).toDouble()
            : double.tryParse(inv['grandTotal'].toString()) ?? 0.0;

        String type = inv['invoiceType'] ?? 'Credit';
        String status = inv['status'] ?? 'Unpaid';

        bool isCash = (type == 'Cash');
        bool isPaidCredit = (type == 'Credit' && status == 'Paid');
        bool isUnpaidCredit = (type == 'Credit' && status != 'Paid');

        Color badgeColor = Colors.grey;
        String badgeText = "Unknown";

        if (isCash) {
          badgeColor = Colors.green;
          badgeText = "Cash";
        } else if (isPaidCredit) {
          badgeColor = Colors.blue;
          badgeText = "Paid";
        } else if (isUnpaidCredit) {
          badgeColor = Colors.orange;
          badgeText = "Unpaid";
        }

        final saved = _parseDate(inv);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$id • ${saved.day}/${saved.month}",
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total.toStringAsFixed(2),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badgeText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
