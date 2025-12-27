import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompareReportPage extends StatefulWidget {
  const CompareReportPage({super.key});

  @override
  State<CompareReportPage> createState() => _CompareReportPageState();
}

class _CompareReportPageState extends State<CompareReportPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> invoices = [];

  DateTimeRange? periodA;
  DateTimeRange? periodB;

  Map<String, dynamic>? resultA;
  Map<String, dynamic>? resultB;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList("invoice_history") ?? [];

    final parsed = <Map<String, dynamic>>[];
    for (final s in raw) {
      try {
        final d = jsonDecode(s);
        if (d is Map<String, dynamic>) parsed.add(d);
      } catch (_) {}
    }

    setState(() => invoices = parsed);
  }

  Future<void> pickA() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: "Select Period A",
      builder: _pickerStyle,
    );
    if (picked != null) {
      setState(() => periodA = picked);
      _calculate();
    }
  }

  Future<void> pickB() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: "Select Period B",
      builder: _pickerStyle,
    );
    if (picked != null) {
      setState(() => periodB = picked);
      _calculate();
    }
  }

  Widget _pickerStyle(context, child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1E88E5),
          onPrimary: Colors.white,
          onSurface: Colors.black87,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Color(0xFF1E88E5)),
        ),
      ),
      child: child!,
    );
  }

  void _calculate() {
    if (periodA != null) resultA = _calc(periodA!);
    if (periodB != null) resultB = _calc(periodB!);
    setState(() {});
  }

  Map<String, dynamic> _calc(DateTimeRange range) {
    final list = invoices.where((inv) {
      final date =
          DateTime.tryParse(inv["savedAt"] ?? inv["invoiceDate"]) ??
          DateTime.now();
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList();

    double total = 0;
    int count = list.length;
    int paid = 0, unpaid = 0;

    for (final i in list) {
      total += (i["grandTotal"] is num) ? i["grandTotal"] : 0.0;
      if (i["status"] == "Paid") {
        paid++;
      } else {
        unpaid++;
      }
    }

    return {"count": count, "total": total, "paid": paid, "unpaid": unpaid};
  }

  String formatRange(DateTimeRange? r) {
    if (r == null) return "-";
    return "${r.start.day}/${r.start.month}/${r.start.year} → ${r.end.day}/${r.end.month}/${r.end.year}";
  }

  Widget _summaryBox(String title, Map<String, dynamic>? data, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 14),
          if (data == null)
            Text(
              "No data selected",
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            )
          else ...[
            _dataLine("Invoices", data["count"].toString()),
            _dataLine("Total Amount", data["total"].toString()),
            _dataLine("Paid", data["paid"].toString()),
            _dataLine("Unpaid", data["unpaid"].toString()),
          ],
        ],
      ),
    );
  }

  Widget _dataLine(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _comparisonCard(String label, num a, num b) {
    final diff = b - a;
    final isIncrease = diff > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          /// Progress bars
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 600),
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(0xFF1E88E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: a.toDouble(),
                ),
              ),
              const SizedBox(width: 10),
              Text("$a"),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 600),
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(0xFFEF5350),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: b.toDouble(),
                ),
              ),
              const SizedBox(width: 10),
              Text("$b"),
            ],
          ),

          const SizedBox(height: 10),

          /// Increase or decrease indicator
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncrease ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                isIncrease
                    ? "Increased by ${diff.abs()}"
                    : "Decreased by ${diff.abs()}",
                style: TextStyle(
                  fontSize: 13,
                  color: isIncrease ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Blue = Color(0xFF1E88E5);
    const Red = Color(0xFFEF5350);

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Blue,
        title: const Text(
          "Compare Reports",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Two Time Periods",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickA,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Blue,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Pick Period A",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickB,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Red,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Pick Period B",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Text(
              "Period A: ${formatRange(periodA)}",
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            _summaryBox("Period A Summary", resultA, Blue),

            const SizedBox(height: 30),

            Text(
              "Period B: ${formatRange(periodB)}",
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            _summaryBox("Period B Summary", resultB, Red),

            const SizedBox(height: 30),

            if (resultA != null && resultB != null) ...[
              const Text(
                "Comparison",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),

              _comparisonCard(
                "Total Amount",
                resultA!["total"],
                resultB!["total"],
              ),
              _comparisonCard(
                "Invoice Count",
                resultA!["count"],
                resultB!["count"],
              ),
              _comparisonCard("Paid", resultA!["paid"], resultB!["paid"]),
              _comparisonCard("Unpaid", resultA!["unpaid"], resultB!["unpaid"]),
            ],
          ],
        ),
      ),
    );
  }
}
