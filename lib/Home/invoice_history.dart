import 'dart:convert';
import 'package:EasyInvoice/Drawer/Security/security_service.dart';
import 'package:EasyInvoice/Home/template_preview.dart';
import 'package:EasyInvoice/Home/invoice_form_page.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';
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
  final Map<String, bool> _selectedIds = {};

  String _search = "";
  DateTimeRange? _range;

  int _mainTabIndex = 0;
  late PageController _pageController;

  int _creditSubTab = 0;

  final Color _primaryColor = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList("invoice_history") ?? []).reversed
        .toList();

    final p = <Map<String, dynamic>>[];
    for (final i in list) {
      try {
        final parsedInvoice = _parse(i);
        p.add(parsedInvoice);
      } catch (_) {}
    }

    setState(() {
      _raw = list;
      _parsed = p;
    });

    _applyFilters();
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
      "invoiceType": "Credit",
      "status": "Unpaid",
    };
  }

  void _applyFilters() {
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
    });
  }

  Future<void> _markAsPaid(Map<String, dynamic> invoice) async {
    final colors = AppColors(context);
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Receive Payment?",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            content: Text(
              "This will move the bill to Credit Paid history.",
              style: GoogleFonts.inter(color: Colors.grey[700]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Confirm Paid",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> currentList = prefs.getStringList("invoice_history") ?? [];
    List<String> updatedList = [];

    for (String itemStr in currentList) {
      try {
        Map<String, dynamic> itemMap = jsonDecode(itemStr);
        if (itemMap['invoiceId'] == invoice['invoiceId'] &&
            itemMap['savedAt'] == invoice['savedAt']) {
          itemMap['status'] = 'Paid';
          updatedList.add(jsonEncode(itemMap));
        } else {
          updatedList.add(itemStr);
        }
      } catch (_) {
        updatedList.add(itemStr);
      }
    }

    await prefs.setStringList("invoice_history", updatedList);
    _load();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bill marked as Paid successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.containsKey(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds[id] = true;
      }
    });
  }

  Future<void> _editInvoice(Map<String, dynamic> invoice) async {
    // Check smart lock first
    bool canProceed = await SecurityService.requireSmartLock();
    if (!canProceed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication required to edit")),
        );
      }
      return;
    }

    // Navigate to form page with edit data
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceFormPage(editData: invoice),
        ),
      );
      // Reload history after returning from edit
      _load();
    }
  }

  Future<void> _deleteSelected() async {
    bool authorized = await SecurityService.requireSmartLock();
    if (!authorized) return;

    if (_selectedIds.isEmpty) return;
    final colors = AppColors(context);

    final ok = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete ${_selectedIds.length} invoice(s)?",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          "This action cannot be undone.",
          style: GoogleFonts.inter(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    final originalStorageList = prefs.getStringList("invoice_history") ?? [];

    originalStorageList.removeWhere((rawString) {
      final p = _parse(rawString);
      String key = "${p['invoiceId']}_${p['savedAt']}";
      return _selectedIds.containsKey(key);
    });

    await prefs.setStringList("invoice_history", originalStorageList);
    _selectedIds.clear();
    _selectionMode = false;
    await _load();
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _range = picked);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        centerTitle: true,
        title: Text(
          _selectionMode
              ? "${_selectedIds.length} selected"
              : "Invoice History",
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          if (!_selectionMode)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.textPrimary,
              ),
              onPressed: () => setState(() => _selectionMode = true),
            ),
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              }),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
              ),
              onPressed: _deleteSelected,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(colors),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SlidingTabSelector(
              labels: const ["Cash Sales", "Credit Sales"],
              selectedIndex: _mainTabIndex,
              onChanged: (index) {
                setState(() => _mainTabIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutQuart,
                );
              },
              activeColor: _primaryColor,
              backgroundColor: colors.card,
              borderColor: colors.border,
              textColor: colors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _mainTabIndex = index),
              children: [_buildCashList(colors), _buildCreditSection(colors)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashList(AppColors colors) {
    final cashInvoices = _filtered.where((i) {
      String type = i['invoiceType'] ?? 'Credit';
      return type == 'Cash';
    }).toList();

    return _buildListView(cashInvoices, isCreditTab: false, colors: colors);
  }

  Widget _buildCreditSection(AppColors colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SlidingTabSelector(
            labels: const ["Unpaid Bills", "Paid History"],
            selectedIndex: _creditSubTab,
            onChanged: (index) => setState(() => _creditSubTab = index),
            activeColor: _creditSubTab == 0
                ? Colors.orangeAccent
                : Colors.greenAccent,
            height: 40,
            fontSize: 12,
            backgroundColor: colors.card,
            borderColor: colors.border,
            textColor: colors.textPrimary,
          ),
        ),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _creditSubTab == 0
                ? _buildCreditUnpaidList(colors)
                : _buildCreditPaidList(colors),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditUnpaidList(AppColors colors) {
    final list = _filtered.where((i) {
      String type = i['invoiceType'] ?? 'Credit';
      String status = i['status'] ?? 'Unpaid';
      return type == 'Credit' && status == 'Unpaid';
    }).toList();

    return _buildListView(
      list,
      isCreditTab: true,
      showPayOption: true,
      colors: colors,
    );
  }

  Widget _buildCreditPaidList(AppColors colors) {
    final list = _filtered.where((i) {
      String type = i['invoiceType'] ?? 'Credit';
      String status = i['status'] ?? 'Unpaid';
      return type == 'Credit' && status == 'Paid';
    }).toList();

    return _buildListView(
      list,
      isCreditTab: true,
      showPayOption: false,
      colors: colors,
    );
  }

  Widget _buildListView(
    List<Map<String, dynamic>> items, {
    bool isCreditTab = false,
    bool showPayOption = false,
    required AppColors colors,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 60, color: colors.border),
            const SizedBox(height: 16),
            Text(
              "No invoices found",
              style: GoogleFonts.inter(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final inv = items[i];
        String uniqueId = "${inv['invoiceId']}_${inv['savedAt']}";
        final isSelected = _selectedIds.containsKey(uniqueId);

        return GestureDetector(
          onTap: () {
            if (_selectionMode) {
              _toggleSelect(uniqueId);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InvoicePreviewPage(data: inv, hideAppBarActions: false),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? _primaryColor.withOpacity(0.1) : colors.card,
              border: Border.all(
                color: isSelected ? _primaryColor : colors.border,
                width: 1.5,
              ),
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? _primaryColor
                            : colors.textSecondary,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: (isCreditTab ? Colors.orange : Colors.green)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isCreditTab
                            ? Icons.credit_score_rounded
                            : Icons.attach_money_rounded,
                        color: isCreditTab ? Colors.orange : Colors.green,
                        size: 24,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv["customerName"] ?? "Unknown",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${inv["invoiceId"]} • ${_shortDate(inv["invoiceDate"])}",
                          style: GoogleFonts.inter(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Total: ${inv["grandTotal"]}",
                          style: GoogleFonts.inter(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showPayOption && !_selectionMode)
                    ElevatedButton(
                      onPressed: () => _markAsPaid(inv),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Pay Bill",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (!_selectionMode)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _editInvoice(inv),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: colors.border),
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

  Widget _buildSearchBar(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: colors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search invoices...",
                        hintStyle: TextStyle(color: colors.textSecondary),
                        contentPadding: const EdgeInsets.only(bottom: 2),
                      ),
                      onChanged: (v) {
                        _search = v;
                        _applyFilters();
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: _range == null
                    ? colors.card
                    : _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _range == null ? colors.border : _primaryColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: _range == null ? colors.textSecondary : _primaryColor,
                size: 22,
              ),
            ),
          ),
          if (_range != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() => _range = null);
                _applyFilters();
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade400,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SlidingTabSelector extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final Function(int) onChanged;
  final Color activeColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double height;
  final double fontSize;

  const SlidingTabSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    required this.activeColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.height = 50,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth = constraints.maxWidth / labels.length;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment(
                  (selectedIndex * 2 / (labels.length - 1)) - 1,
                  0,
                ),
                child: Container(
                  width: tabWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: labels.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final String text = entry.value;
                  final bool isSelected = index == selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(index),
                      behavior: HitTestBehavior.translucent,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: fontSize,
                          ),
                          child: Text(text),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
