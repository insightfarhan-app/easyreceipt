import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:EasyInvoice/Home/template_preview.dart';
import 'package:EasyInvoice/Quotation/quotation_preview.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';
import 'package:EasyInvoice/Services/purchase_history.dart';

class ConvertToInvoicePage extends StatefulWidget {
  const ConvertToInvoicePage({super.key});

  @override
  State<ConvertToInvoicePage> createState() => _ConvertToInvoicePageState();
}

class _ConvertToInvoicePageState extends State<ConvertToInvoicePage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _quotations = [];
  List<Map<String, dynamic>> _filteredQuotes = [];
  bool _isLoading = true;
  String _searchQuery = "";
  Map<String, dynamic>? _selectedQuote;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  String _selectedInvoiceType = 'Credit';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _loadQuotations();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotations() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList("quotation_history") ?? [];

    List<Map<String, dynamic>> loaded = [];
    for (String s in list) {
      try {
        loaded.add(jsonDecode(s));
      } catch (e) {}
    }

    loaded.sort((a, b) {
      String dateA = a['savedAt'] ?? '';
      String dateB = b['savedAt'] ?? '';
      return dateB.compareTo(dateA);
    });

    if (mounted) {
      setState(() {
        _quotations = loaded;
        _isLoading = false;
      });
      _filterList();
      _animController.forward();
    }
  }

  void _filterList() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredQuotes = List.from(_quotations);
      } else {
        _filteredQuotes = _quotations.where((q) {
          final name = (q['customerName'] ?? '').toString().toLowerCase();
          final id = (q['quoteId'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || id.contains(_searchQuery);
        }).toList();
      }
    });
  }

  bool _isQuoteActive(String? validUntilStr) {
    if (validUntilStr == null || validUntilStr.isEmpty) return true;
    try {
      List<String> parts = validUntilStr.split('/');
      if (parts.length != 3) return true;
      DateTime validUntil = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      return !validUntil.isBefore(today);
    } catch (e) {
      return true;
    }
  }

  // --- 2. PREVIEW QUOTATION ---
  void _previewQuotation(Map<String, dynamic> quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuotationPreviewPage(data: quote, hideAppBarActions: true),
      ),
    );
  }

  // --- 3. CONVERSION LOGIC ---
  Future<void> _convertQuoteToInvoice(Map<String, dynamic> quoteData) async {
    final colors = AppColors(context);
    final prefs = await SharedPreferences.getInstance();
    
    // Use PurchaseHistoryService to get history
    List<String> history = await PurchaseHistoryService.getRawHistory();

    // Check if this quotation has already been converted
    String currentQuoteId = quoteData['quoteId']?.toString() ?? '';
    String? existingInvoiceId;

    for (String item in history) {
      try {
        final map = jsonDecode(item);
        if (map['convertedFrom']?.toString() == currentQuoteId) {
          existingInvoiceId = map['invoiceId']?.toString();
          break;
        }
      } catch (_) {}
    }

    // If already converted, show warning dialog
    if (existingInvoiceId != null && mounted) {
      bool? shouldProceed = await _showAlreadyConvertedDialog(
        colors,
        currentQuoteId,
        existingInvoiceId,
      );

      if (shouldProceed != true) {
        return; // User cancelled
      }
    }

    // Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              Text(
                "Converting...",
                style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // A. GENERATE NEW INVOICE ID (Same logic as InvoiceFormPage)
    String startSeqStr = prefs.getString('invoice_sequence') ?? "0000";
    int userStartInt = int.tryParse(startSeqStr) ?? 0;
    int highestHistoryId = 0;

    for (String item in history) {
      try {
        final map = jsonDecode(item);
        String savedId = map['invoiceId']?.toString() ?? "";
        String numPart = savedId.replaceAll(RegExp(r'[^0-9]'), '');
        if (numPart.isNotEmpty) {
          int val = int.tryParse(numPart) ?? 0;
          if (val > highestHistoryId) highestHistoryId = val;
        }
      } catch (_) {}
    }

    int baseNumber = (highestHistoryId >= userStartInt)
        ? highestHistoryId
        : userStartInt;
    int nextIdVal = baseNumber + 1;
    int minLength = startSeqStr.length < 4 ? 4 : startSeqStr.length;
    String newInvoiceId = "INV-${nextIdVal.toString().padLeft(minLength, '0')}";

    // B. CREATE INVOICE DATA OBJECT
    final now = DateTime.now();
    String invoiceDate =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    // Build complete invoice data with all required fields
    final newInvoice = <String, dynamic>{
      // Customer Details
      'customerName': quoteData['customerName'] ?? '',
      'customerPhone': quoteData['customerPhone'] ?? '',
      'customerAddress': quoteData['customerAddress'] ?? '',

      // Invoice Identity
      'invoiceId': newInvoiceId,
      'invoiceDate': invoiceDate,

      // Items and Amounts
      'items': List<Map<String, dynamic>>.from(
        (quoteData['items'] as List?)?.map(
              (item) => Map<String, dynamic>.from(item),
            ) ??
            [],
      ),
      'subtotal': quoteData['subtotal'] ?? 0.0,
      'tax': quoteData['tax'] ?? 0.0,
      'discount': quoteData['discount'] ?? 0.0,
      'grandTotal': quoteData['grandTotal'] ?? 0.0,

      // Invoice Status & Type
      'status': _selectedInvoiceType == 'Cash' ? 'Paid' : 'Unpaid',
      'invoiceType': _selectedInvoiceType,

      // Tracking
      'convertedFrom': quoteData['quoteId'] ?? '',
      'savedAt': DateTime.now().toIso8601String(),
    };

    // C. SAVE TO INVOICE HISTORY using PurchaseHistoryService
    await PurchaseHistoryService.addOrUpdatePurchase(newInvoice);

    // D. CLOSE LOADING & NAVIGATE DIRECTLY TO PREVIEW
    if (mounted) {
      Navigator.pop(context); // Close Loader

      // Navigate directly to Invoice Preview (replacing current page)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InvoicePreviewPage(data: newInvoice, hideAppBarActions: false),
        ),
      );

      // Show success snackbar after navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Invoice $newInvoiceId created successfully!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  // --- 3.5 SHOW ALREADY CONVERTED WARNING DIALOG ---
  Future<bool?> _showAlreadyConvertedDialog(
    AppColors colors,
    String quoteId,
    String existingInvoiceId,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                "Already Converted",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                "This quotation ($quoteId) has already been converted to an invoice.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Existing Invoice Info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Existing: $existingInvoiceId",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "Do you still want to generate a new invoice?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colors.border),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Still Generate",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. SHOW CONVERT CONFIRMATION BOTTOM SHEET ---
  void _showConvertBottomSheet(Map<String, dynamic> quote) {
    final colors = AppColors(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primary.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.transform_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Convert to Sale Invoice",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Quotation ${quote['quoteId']}",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Quote Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      "Customer",
                      quote['customerName'] ?? 'Unknown',
                      colors,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      "Items",
                      "${(quote['items'] as List?)?.length ?? 0}",
                      colors,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      "Total Amount",
                      "${(quote['grandTotal'] ?? 0.0).toStringAsFixed(2)}",
                      colors,
                      isBold: true,
                      valueColor: colors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Invoice Type Selection
              Text(
                "Select Invoice Type",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInvoiceTypeOption(
                      "Cash",
                      Icons.payments_rounded,
                      Colors.green,
                      colors,
                      setModalState,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInvoiceTypeOption(
                      "Credit",
                      Icons.credit_card_rounded,
                      Colors.orange,
                      colors,
                      setModalState,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: colors.border),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _convertQuoteToInvoice(quote);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Convert Now",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceTypeOption(
    String type,
    IconData icon,
    Color color,
    AppColors colors,
    StateSetter setModalState,
  ) {
    bool isSelected = _selectedInvoiceType == type;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedInvoiceType = type;
        });
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : colors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : colors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: GoogleFonts.inter(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    AppColors colors, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // --- UI CONSTRUCTION ---

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(colors),
            _buildSearchAndFilter(colors),
            const SizedBox(height: 8),
            _buildInfoBanner(colors),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(colors)
                  : _filteredQuotes.isEmpty
                  ? _buildEmptyState(colors)
                  : _buildQuotationList(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildNavButton(Icons.arrow_back_ios_new_rounded, colors, () {
            Navigator.pop(context);
          }),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Convert to Invoice",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Select a quotation to convert",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  "${_quotations.length}",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, AppColors colors, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: 20, color: colors.textPrimary),
      ),
    );
  }

  Widget _buildSearchAndFilter(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: "Search by customer name or quote ID...",
            hintStyle: GoogleFonts.inter(
              color: colors.textSecondary.withOpacity(0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: colors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.08),
            colors.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Tap a quotation to convert it to a sale invoice. Use the preview button to check details first.",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 16),
          Text(
            "Loading quotations...",
            style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.border.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? Icons.folder_open_rounded
                    : Icons.search_off_rounded,
                size: 56,
                color: colors.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? "No Quotations Found" : "No Results Found",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? "Create a quotation first to convert it to an invoice"
                  : "Try searching with different keywords",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationList(AppColors colors) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredQuotes.length,
        itemBuilder: (context, index) {
          return _buildQuotationCard(_filteredQuotes[index], colors, index);
        },
      ),
    );
  }

  Widget _buildQuotationCard(
    Map<String, dynamic> quote,
    AppColors colors,
    int index,
  ) {
    bool isActive = _isQuoteActive(quote['validUntil']);
    bool isSelected = _selectedQuote == quote;
    String quoteId = quote['quoteId'] ?? '---';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedQuote = quote;
          });
          _showConvertBottomSheet(quote);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? colors.primary.withOpacity(0.1)
                    : Colors.black.withOpacity(0.03),
                blurRadius: isSelected ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primary,
                            colors.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quoteId,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildStatusBadge(isActive, colors),
                        const SizedBox(width: 8),
                        // Preview Button
                        InkWell(
                          onTap: () => _previewQuotation(quote),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: Colors.purple.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Customer Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote['customerName'] ?? 'Unknown Customer',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${(quote['items'] as List?)?.length ?? 0} Items",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                quote['date'] ?? '',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Total",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${(quote['grandTotal'] ?? 0).toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Convert Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary,
                        colors.primary.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.transform_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Convert to Sale Invoice",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, AppColors colors) {
    final Color statusColor = isActive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? "Active" : "Expired",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
