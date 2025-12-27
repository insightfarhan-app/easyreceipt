import 'dart:convert';
import 'package:EasyInvoice/Home/template_preview.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceHistory extends StatefulWidget {
  const InvoiceHistory({super.key});

  @override
  State<InvoiceHistory> createState() => _InvoiceHistoryState();
}

class _InvoiceHistoryState extends State<InvoiceHistory>
    with SingleTickerProviderStateMixin {
  List<String> _raw = [];
  List<Map<String, dynamic>> _parsed = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _selectionMode = false;
  final Map<int, bool> _selected = {};
  String _search = "";
  DateTimeRange? _range;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1,
    );
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("invoice_history") ?? [];

    final p = <Map<String, dynamic>>[];
    for (final i in list) {
      try {
        final parsedInvoice = _parse(i);
        parsedInvoice['status'] ??= 'Unpaid';
        p.add(parsedInvoice);
      } catch (_) {}
    }

    setState(() {
      _raw = list;
      _parsed = p;
    });

    _apply();
  }

  Map<String, dynamic> _parse(String s) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    return {
      "invoiceId": "INV-UNKNOWN",
      "customerName": "Unknown",
      "grandTotal": 0,
      "invoiceDate": DateTime.now().toIso8601String(),
      "savedAt": DateTime.now().toIso8601String(),
      "status": "Unpaid",
    };
  }

  void _apply() {
    var list = List<Map<String, dynamic>>.from(_parsed);

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((i) {
        return i["invoiceId"].toString().toLowerCase().contains(q) ||
            i["customerName"].toString().toLowerCase().contains(q);
      }).toList();
    }

    if (_range != null) {
      list = list.where((i) {
        final dt =
            DateTime.tryParse(i["savedAt"] ?? "") ??
            DateTime.tryParse(i["invoiceDate"] ?? "") ??
            DateTime.now();

        return !dt.isBefore(_range!.start) && !dt.isAfter(_range!.end);
      }).toList();
    }

    setState(() {
      _filtered = list;
      _selected.removeWhere((i, _) => i >= _filtered.length);
    });
  }

  void _toggleSelect(int idx) {
    setState(() {
      _selected[idx] = !(_selected[idx] ?? false);
    });
  }

  Future<void> _deleteSelected() async {
    final indices =
        _selected.entries.where((e) => e.value).map((e) => e.key).toList()
          ..sort((a, b) => b.compareTo(a));

    if (indices.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No invoices selected")));
      return;
    }

    final ok = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          "Delete ${indices.length} invoice(s)?",
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          "This action cannot be undone.",
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final raw = List<String>.from(_raw);

    for (final fIndex in indices) {
      final inv = _filtered[fIndex];
      final int match = raw.indexWhere((rawItem) {
        final p = _parse(rawItem);
        return p["invoiceId"] == inv["invoiceId"] &&
            p["savedAt"] == inv["savedAt"];
      });

      if (match >= 0) raw.removeAt(match);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("invoice_history", raw);

    await _load();
    setState(() => _selectionMode = false);
  }

  String _shortDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return iso;
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _range,
    );

    if (picked != null) {
      setState(() => _range = picked);
      _apply();
    }
  }

  Future<void> _toggleStatus(int index) async {
    final inv = _filtered[index];
    final newStatus = inv['status'] == 'Paid' ? 'Unpaid' : 'Paid';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Change Status",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to mark this invoice as $newStatus?",
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      inv['status'] = newStatus;
    });

    final prefs = await SharedPreferences.getInstance();
    final updatedList = _parsed.map((inv) => jsonEncode(inv)).toList();
    await prefs.setStringList('invoice_history', updatedList);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invoice status updated to $newStatus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _selectionMode
              ? "${_selected.values.where((v) => v).length} selected"
              : "Invoice History",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => setState(() => _selectionMode = true),
            ),
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectionMode = false;
                _selected.clear();
              }),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteSelected,
            ),
          ],
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
            ),
          ),
        ),
      ),
      floatingActionButton: _selectionMode
          ? FloatingActionButton.extended(
              backgroundColor: Colors.red,
              label: const Text("Delete Selected"),
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteSelected,
            )
          : null,
      body: Column(
        children: [
          _buildSearchBar(primaryColor),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color primary) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search invoice ID or customer",
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      onChanged: (v) {
                        _search = v;
                        _apply();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _pickRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _range == null
                    ? Colors.white12
                    : primary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.date_range,
                color: _range == null ? Colors.white54 : Colors.white,
              ),
            ),
          ),
          if (_range != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() => _range = null);
                _apply();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Text(
          "No invoices found",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final inv = _filtered[i];
        final sel = _selected[i] ?? false;

        inv['status'] ??= 'Unpaid';

        return GestureDetector(
          onTap: () {
            if (_selectionMode) {
              _toggleSelect(i);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InvoicePreviewPage(data: inv, hideAppBarActions: true),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: sel
                  ? LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade900, Colors.grey.shade50],
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: sel ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              leading: _selectionMode
                  ? Checkbox(
                      value: sel,
                      onChanged: (_) => _toggleSelect(i),
                      activeColor: Colors.blueAccent,
                    )
                  : const Icon(Icons.receipt_long, color: Colors.white),
              title: Text(
                inv["customerName"] ?? "Unknown",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ID: ${inv["invoiceId"]}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "Date: ${_shortDate(inv["invoiceDate"])}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                  Text(
                    "Total: ${inv["grandTotal"]}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              trailing: InkWell(
                onTap: () => _toggleStatus(i),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: inv['status'] == 'Paid'
                        ? Colors.green
                        : Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    inv['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
