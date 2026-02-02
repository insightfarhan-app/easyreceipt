import 'package:EasyInvoice/Quotation/quotation_preview.dart';
import 'package:EasyInvoice/Quotation/quotation_formpage.dart';
import 'package:EasyInvoice/Drawer/Security/security_service.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuotationHistoryPage extends StatefulWidget {
  const QuotationHistoryPage({super.key});

  @override
  State<QuotationHistoryPage> createState() => _QuotationHistoryPageState();
}

class _QuotationHistoryPageState extends State<QuotationHistoryPage>
    with SingleTickerProviderStateMixin {
  // Data
  List<Map<String, dynamic>> _allQuotes = [];
  List<Map<String, dynamic>> _filteredQuotes = [];
  bool _isLoading = true;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  bool _showActive = true; // true = Active, false = Expired

  // Theme Colors (Navy Blue Professional)
  final Color _primaryColor = const Color(0xFF1E40AF);
  final Color _expiredColor = const Color(0xFFEF4444);
  final Color _activeColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA LOADING & LOGIC ---

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList("quotation_history") ?? [];

    List<Map<String, dynamic>> loaded = [];
    for (String s in list) {
      try {
        loaded.add(jsonDecode(s));
      } catch (e) {
        // Skip corrupted data
      }
    }

    // Sort by savedAt (newest first)
    loaded.sort((a, b) {
      String dateA = a['savedAt'] ?? '';
      String dateB = b['savedAt'] ?? '';
      return dateB.compareTo(dateA);
    });

    if (mounted) {
      setState(() {
        _allQuotes = loaded;
        _isLoading = false;
      });
      _filterList();
    }
  }

  Future<void> _deleteQuote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allQuotes.removeWhere((element) => element['quoteId'] == id);
      _filterList();
    });

    // Update Prefs
    List<String> stringList = _allQuotes.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList("quotation_history", stringList);
  }

  Future<void> _confirmAndDeleteQuote(String id) async {
    // Check smart lock first
    bool canProceed = await SecurityService.requireSmartLock();
    if (!canProceed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication required to delete")),
        );
      }
      return;
    }

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Quotation?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteQuote(id);
    }
  }

  Future<void> _editQuotation(Map<String, dynamic> quote) async {
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
          builder: (context) => QuotationFormPage(editData: quote),
        ),
      );
      // Reload history after returning from edit
      _loadHistory();
    }
  }

  bool _isQuoteActive(String? validUntilStr) {
    if (validUntilStr == null || validUntilStr.isEmpty) {
      return true; // Assume active if no date
    }
    try {
      // Expecting "dd/MM/yyyy"
      List<String> parts = validUntilStr.split('/');
      if (parts.length != 3) return true;
      DateTime validUntil = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      // Compare with today (stripped of time)
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      return !validUntil.isBefore(today);
    } catch (e) {
      return true;
    }
  }

  void _filterList() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredQuotes = _allQuotes.where((quote) {
        // 1. Search Filter
        bool matchesSearch = false;
        String id = (quote['quoteId'] ?? '').toString().toLowerCase();
        String name = (quote['customerName'] ?? '').toString().toLowerCase();

        if (query.isEmpty) {
          matchesSearch = true;
        } else {
          matchesSearch = id.contains(query) || name.contains(query);
        }

        // 2. Status Filter (Toggle)
        bool isActive = _isQuoteActive(quote['validUntil']);
        bool matchesStatus = _showActive ? isActive : !isActive;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Quotation History",
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildTopControls(colors),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : _filteredQuotes.isEmpty
                ? _buildEmptyState(colors)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredQuotes.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(_filteredQuotes[index], colors);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: colors.background,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            style: GoogleFonts.inter(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: "Search customer or ID...",
              hintStyle: GoogleFonts.inter(color: colors.textSecondary),
              prefixIcon: Icon(Icons.search, color: colors.textSecondary),
              filled: true,
              fillColor: colors.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Toggle Switch
          _buildToggleSwitch(colors),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(AppColors colors) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: colors.border,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.decelerate,
            alignment: _showActive
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width:
                  MediaQuery.of(context).size.width *
                  0.44, // Approx half width minus padding
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _showActive = true;
                    _filterList();
                  }),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      "Active",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: _showActive
                            ? _primaryColor
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _showActive = false;
                    _filterList();
                  }),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      "Expired",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: !_showActive
                            ? _expiredColor
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> quote, AppColors colors) {
    bool isActive = _isQuoteActive(quote['validUntil']);
    String id = quote['quoteId'] ?? '---';

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: Colors.red.shade700),
      ),
      confirmDismiss: (direction) async {
        // Check smart lock first
        bool canProceed = await SecurityService.requireSmartLock();
        if (!canProceed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Authentication required to delete"),
              ),
            );
          }
          return false;
        }

        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Quotation?"),
            content: const Text("This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteQuote(id),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuotationPreviewPage(data: quote, hideAppBarActions: false),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      id,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildStatusChip(isActive),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _editQuotation(quote),
                        child: Container(
                          padding: const EdgeInsets.all(6),
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
                      GestureDetector(
                        onTap: () => _confirmAndDeleteQuote(id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                quote['customerName'] ?? 'Unknown Customer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Created: ${quote['date']}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Valid Until",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        quote['validUntil'] ?? 'N/A',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Amount",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "${(quote['grandTotal'] ?? 0.0).toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? _activeColor.withOpacity(0.1)
            : _expiredColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? _activeColor.withOpacity(0.3)
              : _expiredColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.history,
            size: 12,
            color: isActive ? _activeColor : _expiredColor,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? "Active" : "Expired",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? _activeColor : _expiredColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: colors.border,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? "No ${_showActive ? 'active' : 'expired'} quotations found"
                : "No results for \"${_searchController.text}\"",
            style: GoogleFonts.inter(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
