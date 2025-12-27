import 'dart:convert';
import 'dart:math';

import 'package:EasyInvoice/Home/compare_report.dart';
import 'package:EasyInvoice/Home/template_preview.dart';
import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = true;
  ReportRange _range = ReportRange.daily;

  double totalSales = 0;
  int invoiceCount = 0;
  int paidCount = 0;
  int unpaidCount = 0;
  int totalProducts = 0;
  double paidSales = 0;
  double unpaidSales = 0;
  List<String> chartLabels = [];
  List<double> chartValues = [];

  late AnimationController _animCtrl;

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
          decoded['grandTotal'] ??= 0;
          decoded['savedAt'] ??= DateTime.now().toIso8601String();
          parsed.add(decoded);
        }
      } catch (_) {}
    }

    setState(() {
      _invoices = parsed;
      _loading = false;
    });

    _recompute();
    _animCtrl.forward();
  }

  DateTime _parseDate(String? iso) {
    try {
      if (iso == null) return DateTime.now();
      return DateTime.parse(iso);
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
        start = now.subtract(const Duration(days: 6));
        break;
      case ReportRange.weekly:
        start = now.subtract(const Duration(days: 7 * 12 - 1));
        break;
      case ReportRange.monthly:
        start = DateTime(now.year, now.month - 11, 1);
        break;
      case ReportRange.yearly:
        start = DateTime(now.year - 4, 1, 1);
        break;
      case ReportRange.overall:
        start = DateTime(1970);
        break;
    }

    for (final inv in _invoices) {
      final saved = _parseDate(inv['savedAt'] ?? inv['invoiceDate']);
      if (!saved.isBefore(start) && !saved.isAfter(end)) filtered.add(inv);
    }

    double total = 0;
    int invoices = 0;
    int paid = 0;
    int unpaid = 0;
    int products = 0;
    double paidSum = 0;
    double unpaidSum = 0;

    for (final inv in filtered) {
      final g = (inv['grandTotal'] is num)
          ? (inv['grandTotal'] as num).toDouble()
          : double.tryParse(inv['grandTotal'].toString()) ?? 0.0;
      total += g;
      invoices += 1;
      final status = (inv['status'] ?? 'Unpaid').toString().toLowerCase();
      if (status == 'paid') {
        paid++;
        paidSum += g;
      } else {
        unpaid++;
        unpaidSum += g;
      }

      if (inv['items'] is List) {
        final items = inv['items'] as List;
        for (final it in items) {
          if (it is Map && it.containsKey('quantity')) {
            final q = (it['quantity'] is num)
                ? (it['quantity'] as num).toInt()
                : int.tryParse(it['quantity'].toString()) ?? 0;
            products += q;
          } else {
            products += 1;
          }
        }
      }
    }

    // chart
    List<String> labels = [];
    List<double> values = [];
    if (_range == ReportRange.daily) {
      for (int i = 6; i >= 0; i--) {
        final d = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        labels.add("${d.day}/${d.month}");
        double sumForDay = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv['savedAt'] ?? inv['invoiceDate']);
          if (saved.year == d.year &&
              saved.month == d.month &&
              saved.day == d.day) {
            sumForDay += (inv['grandTotal'] is num)
                ? (inv['grandTotal'] as num).toDouble()
                : 0.0;
          }
        }
        values.add(sumForDay);
      }
    } else if (_range == ReportRange.weekly) {
      final weekLabels = <String>[];
      final weekValues = <double>[];
      for (int w = 11; w >= 0; w--) {
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1))
            .subtract(Duration(days: 7 * w));
        final weekEnd = weekStart.add(const Duration(days: 6));
        weekLabels.add("${weekStart.day}/${weekStart.month}");
        double s = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv['savedAt'] ?? inv['invoiceDate']);
          if (!saved.isBefore(weekStart) && !saved.isAfter(weekEnd)) {
            s += (inv['grandTotal'] is num)
                ? (inv['grandTotal'] as num).toDouble()
                : 0.0;
          }
        }
        weekValues.add(s);
      }
      labels = weekLabels;
      values = weekValues;
    } else if (_range == ReportRange.monthly) {
      for (int m = 11; m >= 0; m--) {
        final date = DateTime(now.year, now.month - m, 1);
        labels.add("${date.month}/${date.year % 100}");
        double s = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv['savedAt'] ?? inv['invoiceDate']);
          if (saved.year == date.year && saved.month == date.month) {
            s += (inv['grandTotal'] is num)
                ? (inv['grandTotal'] as num).toDouble()
                : 0.0;
          }
        }
        values.add(s);
      }
    } else if (_range == ReportRange.yearly) {
      for (int y = 4; y >= 0; y--) {
        final yr = now.year - y;
        labels.add("$yr");
        double s = 0;
        for (final inv in filtered) {
          final saved = _parseDate(inv['savedAt'] ?? inv['invoiceDate']);
          if (saved.year == yr) {
            s += (inv['grandTotal'] is num)
                ? (inv['grandTotal'] as num).toDouble()
                : 0.0;
          }
        }
        values.add(s);
      }
    } else {
      final dates = filtered
          .map((e) => _parseDate(e['savedAt'] ?? e['invoiceDate']))
          .toList();
      if (dates.isEmpty) {
        labels = [];
        values = [];
      } else {
        final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
        final months = <DateTime>[];
        DateTime cursor = DateTime(earliest.year, earliest.month, 1);
        while (!cursor.isAfter(DateTime(now.year, now.month, 1))) {
          months.add(cursor);
          cursor = DateTime(cursor.year, cursor.month + 1, 1);
          if (months.length > 36) break;
        }
        for (final m in months) {
          labels.add("${m.month}/${m.year % 100}");
          double s = 0;
          for (final inv in filtered) {
            final saved = _parseDate(inv['savedAt'] ?? inv['invoiceDate']);
            if (saved.year == m.year && saved.month == m.month) {
              s += (inv['grandTotal'] is num)
                  ? (inv['grandTotal'] as num).toDouble()
                  : 0.0;
            }
          }
          values.add(s);
        }
      }
    }

    setState(() {
      totalSales = total;
      invoiceCount = invoices;
      paidCount = paid;
      unpaidCount = unpaid;
      totalProducts = products;
      paidSales = paidSum;
      unpaidSales = unpaidSum;
      chartLabels = labels;
      chartValues = values;
    });
  }

  void _onRangeChanged(ReportRange r) {
    setState(() => _range = r);
    _recompute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Invoice Reports",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadInvoices,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _glassSummaryCard()),
                          const SizedBox(width: 12),
                          _rangeSelector(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _actionButton(),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _glassKpiCard("Invoices", "$invoiceCount"),
                          _glassKpiCard("Paid", "$paidCount"),
                          _glassKpiCard("Unpaid", "$unpaidCount"),
                          _glassKpiCard("Total Products", "$totalProducts"),
                          _glassKpiCard(
                            "Total Sales",
                            totalSales.toStringAsFixed(2),
                          ),
                          _glassKpiCard(
                            "Paid Sales",
                            paidSales.toStringAsFixed(2),
                          ),
                          _glassKpiCard(
                            "Unpaid Sales",
                            unpaidSales.toStringAsFixed(2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _chartCard(),
                      const SizedBox(height: 24),
                      Text(
                        "Recent invoices",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _recentListTilePreview(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _glassSummaryCard() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Report Overview",
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              totalSales.toStringAsFixed(2),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$invoiceCount invoices",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _smallBadge(
                  Icons.check_circle,
                  "Paid",
                  "$paidCount",
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _smallBadge(
                  Icons.pending,
                  "Unpaid",
                  "$unpaidCount",
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBadge(IconData icon, String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: bg),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeSelector() {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportRange>(
          value: _range,
          isExpanded: true,
          dropdownColor: Colors.black87,
          items: const [
            DropdownMenuItem(value: ReportRange.daily, child: Text("Daily")),
            DropdownMenuItem(value: ReportRange.weekly, child: Text("Weekly")),
            DropdownMenuItem(
              value: ReportRange.monthly,
              child: Text("Monthly"),
            ),
            DropdownMenuItem(value: ReportRange.yearly, child: Text("Yearly")),
            DropdownMenuItem(
              value: ReportRange.overall,
              child: Text("Overall"),
            ),
          ],
          style: const TextStyle(color: Colors.white),
          onChanged: (v) {
            if (v != null) _onRangeChanged(v);
          },
        ),
      ),
    );
  }

  Widget _glassKpiCard(String title, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompareReportPage()),
        );
      },
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: "Compare Reports",
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
            prefixIcon: const Icon(
              Icons.compare_arrows_rounded,
              color: Colors.white,
            ),
            filled: true,
            fillColor: const Color(0xFF1E88E5),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chartCard() {
    if (chartValues.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        height: 220,
        child: Center(
          child: Text(
            "No data for this range",
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ),
      );
    }

    double maxY = chartValues.reduce(max);
    int ticks = 5;
    double interval = (maxY / ticks).ceilToDouble();
    if (interval == 0) interval = 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sales chart",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.only(right: 6.0, top: 8),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: maxY * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "${value.toInt()}",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white70,
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
                          return Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          );
                        },
                        reservedSize: 48,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(chartValues.length, (i) {
                    final v = chartValues[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: v,
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentListTilePreview() {
    final sorted = List<Map<String, dynamic>>.from(_invoices);
    sorted.sort((a, b) {
      final da = _parseDate(a['savedAt'] ?? a['invoiceDate']);
      final db = _parseDate(b['savedAt'] ?? b['invoiceDate']);
      return db.compareTo(da);
    });

    final show = sorted.take(5).toList();

    if (show.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "No invoices yet",
            style: GoogleFonts.inter(color: Colors.white70),
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
            : 0.0;
        final status = (inv['status'] ?? 'Unpaid').toString();
        final saved = _parseDate(inv['savedAt'] ?? inv['invoiceDate']);

        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          child: ListTile(
            leading: Icon(
              Icons.receipt_long,
              color: status.toLowerCase() == 'paid'
                  ? Colors.green
                  : Colors.orange,
            ),
            title: Text(
              customer,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              "$id • ${saved.day}/${saved.month}/${saved.year}",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  total.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: status.toLowerCase() == 'paid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InvoicePreviewPage(data: inv, hideAppBarActions: true),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
