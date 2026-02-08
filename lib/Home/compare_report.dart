import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:EasyInvoice/Services/purchase_history.dart';

class CompareReportPage extends StatefulWidget {
  const CompareReportPage({super.key});

  @override
  State<CompareReportPage> createState() => _CompareReportPageState();
}

class _CompareReportPageState extends State<CompareReportPage> {
  // Data
  List<Map<String, dynamic>> invoices = [];
  bool loading = true;

  // Selection
  DateTimeRange? periodA;
  DateTimeRange? periodB;

  // Calculated Results
  Map<String, dynamic>? statsA;
  Map<String, dynamic>? statsB;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await PurchaseHistoryService.getRawHistory();
    final parsed = <Map<String, dynamic>>[];

    for (final s in list) {
      try {
        final d = jsonDecode(s);
        if (d is Map<String, dynamic>) {
          // Normalize data
          d['savedAt'] ??= d['invoiceDate'] ?? DateTime.now().toIso8601String();
          d['grandTotal'] = (d['grandTotal'] is num) ? d['grandTotal'] : 0.0;
          d['status'] ??= 'Unpaid';
          parsed.add(d);
        }
      } catch (_) {}
    }

    setState(() {
      invoices = parsed;
      loading = false;
    });
  }

  // --- LOGIC ---

  Map<String, dynamic> _calculateStats(DateTimeRange range) {
    final filtered = invoices.where((inv) {
      final date = DateTime.tryParse(inv['savedAt']) ?? DateTime.now();
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList();

    double total = 0;
    int paid = 0;
    int unpaid = 0;

    for (final i in filtered) {
      total += i['grandTotal'];
      if (i['status'].toString().toLowerCase() == 'paid') {
        paid++;
      } else {
        unpaid++;
      }
    }

    return {
      "count": filtered.length,
      "total": total,
      "paid": paid,
      "unpaid": unpaid,
    };
  }

  void _updateStats() {
    setState(() {
      if (periodA != null) statsA = _calculateStats(periodA!);
      if (periodB != null) statsB = _calculateStats(periodB!);
    });
  }

  // --- DATE SELECTION (The "Premium" Way) ---

  void _showPeriodSelector(bool isPeriodA) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPeriodA
                  ? "Select Period A (Baseline)"
                  : "Select Period B (Comparison)",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _presetButton("Last 7 Days", 7, isPeriodA),
            _presetButton("Last 30 Days", 30, isPeriodA),
            _presetButton("This Month", 0, isPeriodA, mode: 'month'),
            _presetButton("Previous Month", 0, isPeriodA, mode: 'prev_month'),
            const Divider(color: Colors.white24, height: 30),
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: Color(0xFF1E88E5),
              ),
              title: const Text(
                "Custom Range",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickCustomDate(isPeriodA);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetButton(String text, int days, bool isPeriodA, {String? mode}) {
    return ListTile(
      title: Text(text, style: const TextStyle(color: Colors.white70)),
      onTap: () {
        DateTime now = DateTime.now();
        DateTime start, end;

        if (mode == 'month') {
          start = DateTime(now.year, now.month, 1);
          end = now;
        } else if (mode == 'prev_month') {
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0); // Last day of prev month
        } else {
          end = now;
          start = now.subtract(Duration(days: days));
        }

        setState(() {
          if (isPeriodA) {
            periodA = DateTimeRange(start: start, end: end);
          } else {
            periodB = DateTimeRange(start: start, end: end);
          }
          _updateStats();
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _pickCustomDate(bool isPeriodA) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: isPeriodA ? periodA : periodB,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPeriodA) {
          periodA = picked;
        } else {
          periodB = picked;
        }
        _updateStats();
      });
    }
  }

  String _fmtDate(DateTime d) => "${d.day}/${d.month}";

  // --- UI BUILDING BLOCKS ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Compare Reports",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Ambient Background Gradient
          Positioned(
            top: -100,
            right: -100,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E88E5).withOpacity(0.2),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 1200 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. SELECTORS
                      Row(
                        children: [
                          Expanded(child: _buildSelectorCard(true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSelectorCard(false)),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 2. COMPARISON CONTENT
                      if (statsA != null && statsB != null) ...[
                        Text(
                          "Performance Analysis",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTotalSalesCard(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard(
                                "Invoices",
                                "count",
                                false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMiniStatCard(
                                "Paid Count",
                                "paid",
                                false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildMiniStatCard(
                          "Unpaid Invoices",
                          "unpaid",
                          true,
                        ), // Inverse Logic
                      ] else ...[
                        // Empty State
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                size: 64,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Select two periods to begin comparison",
                                style: GoogleFonts.inter(color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard(bool isA) {
    final range = isA ? periodA : periodB;
    final color = isA ? const Color(0xFF1E88E5) : const Color(0xFFE91E63);
    final label = isA ? "Period A" : "Period B";

    return GestureDetector(
      onTap: () => _showPeriodSelector(isA),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: range != null ? color.withOpacity(0.5) : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            if (range != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_fmtDate(range.start)} - ${_fmtDate(range.end)}",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "${range.duration.inDays + 1} Days",
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            else
              Text(
                "Tap to select",
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSalesCard() {
    final valA = statsA!['total'] as double;
    final valB = statsB!['total'] as double;
    final diff = valB - valA;
    final pct = valA == 0 ? 100.0 : ((diff / valA) * 100);
    final isPositive = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Revenue",
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valB.toStringAsFixed(2),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${pct.abs().toStringAsFixed(1)}%",
                      style: GoogleFonts.inter(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Comparison Bars
          _buildBar("Period A", valA, const Color(0xFF1E88E5), valA, valB),
          const SizedBox(height: 10),
          _buildBar("Period B", valB, const Color(0xFFE91E63), valA, valB),
        ],
      ),
    );
  }

  Widget _buildBar(
    String label,
    double val,
    Color color,
    double valA,
    double valB,
  ) {
    double maxVal = valA > valB ? valA : valB;
    if (maxVal == 0) maxVal = 1;
    final widthFactor = (val / maxVal).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: widthFactor,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          val.toStringAsFixed(0),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, String key, bool inverseColors) {
    final valA = statsA![key] as int;
    final valB = statsB![key] as int;
    final diff = valB - valA;

    // For 'Unpaid', an increase is BAD (Red), decrease is GOOD (Green)
    // For others, increase is GOOD (Green)
    bool isGood = inverseColors ? diff <= 0 : diff >= 0;
    Color indicatorColor = isGood ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$valB",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (diff != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: indicatorColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${diff > 0 ? '+' : ''}$diff",
                    style: GoogleFonts.inter(
                      color: indicatorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "vs $valA prev",
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
