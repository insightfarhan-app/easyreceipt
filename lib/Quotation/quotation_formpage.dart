import 'package:EasyInvoice/Quotation/quotation_preview.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuotationFormPage extends StatefulWidget {
  final Map<String, dynamic>? editData;

  const QuotationFormPage({super.key, this.editData});

  @override
  State<QuotationFormPage> createState() => _QuotationFormPageState();
}

class _QuotationFormPageState extends State<QuotationFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _customerName = TextEditingController();
  final _customerAddress = TextEditingController();
  final _customerPhone = TextEditingController();
  final _taxController = TextEditingController();
  final _discountController = TextEditingController();

  // State
  bool _isPercentageMode = false;
  List<Map<String, dynamic>> items = [];

  // Quotation Specifics
  String quoteId = "QTN-....";
  String dateIssued = "";
  DateTime? _validUntilDate;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Professional Palette (Navy Blue Theme)
  final Color _primaryColor = const Color(0xFF1E40AF);
  final Color _accentColor = const Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();

    // Check if we're editing existing quotation
    if (widget.editData != null) {
      _loadEditData();
    } else {
      _generateQuoteDetails();
    }

    _loadPreferences();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customerName.dispose();
    _customerAddress.dispose();
    _customerPhone.dispose();
    _taxController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // --- LOGIC: ID GENERATION (QTN-XXXX) ---
  Future<void> _generateQuoteDetails() async {
    final now = DateTime.now();
    setState(() {
      dateIssued =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
      // Default validity is 15 days from now
      _validUntilDate = now.add(const Duration(days: 15));
    });

    final prefs = await SharedPreferences.getInstance();

    // 1. Get the starting sequence for QUOTATIONS specifically
    String startSeqStr = prefs.getString('quotation_sequence') ?? "0000";
    int userStartInt = int.tryParse(startSeqStr) ?? 0;

    // 2. Check quotation_history for the last ID used
    List<String> history = prefs.getStringList("quotation_history") ?? [];
    int highestHistoryId = 0;

    for (String item in history) {
      try {
        final map = jsonDecode(item);
        String savedId = map['quoteId']?.toString() ?? "";
        // Extract number from QTN-0001
        String numPart = savedId.replaceAll(RegExp(r'[^0-9]'), '');
        if (numPart.isNotEmpty) {
          int val = int.tryParse(numPart) ?? 0;
          if (val > highestHistoryId) {
            highestHistoryId = val;
          }
        }
      } catch (_) {}
    }

    // 3. Determine next ID
    int baseNumber = (highestHistoryId >= userStartInt)
        ? highestHistoryId
        : userStartInt;
    int nextIdVal = baseNumber + 1;
    int minLength = startSeqStr.length < 4 ? 4 : startSeqStr.length;

    if (mounted) {
      setState(() {
        quoteId = "QTN-${nextIdVal.toString().padLeft(minLength, '0')}";
      });
    }
  }

  // Load existing quotation data for editing
  void _loadEditData() {
    if (widget.editData == null) return;

    final data = widget.editData!;

    setState(() {
      // Load basic info
      quoteId = data['quoteId'] ?? 'QTN-....';
      dateIssued = data['date'] ?? '';

      // Load customer details
      _customerName.text = data['customerName'] ?? '';
      _customerAddress.text = data['customerAddress'] ?? '';
      _customerPhone.text = data['customerPhone'] ?? '';

      // Load items
      if (data['items'] != null) {
        items = List<Map<String, dynamic>>.from(data['items']);
      }

      // Load tax and discount
      _taxController.text = data['tax']?.toString() ?? '0';
      _discountController.text = data['discount']?.toString() ?? '0';

      // Load validity date
      if (data['validUntil'] != null &&
          data['validUntil'].toString().isNotEmpty) {
        try {
          // Parse date from string format "dd/MM/yyyy"
          final parts = data['validUntil'].toString().split('/');
          if (parts.length == 3) {
            _validUntilDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (e) {
          _validUntilDate = DateTime.now().add(const Duration(days: 15));
        }
      } else {
        _validUntilDate = DateTime.now().add(const Duration(days: 15));
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPercentageMode = prefs.getBool('isPercentageMode_quote') ?? false;
    });
  }

  Future<void> _saveQuoteToHistory(Map<String, dynamic> quoteData) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("quotation_history") ?? [];

    int existingIndex = -1;
    for (int i = 0; i < list.length; i++) {
      try {
        final existing = jsonDecode(list[i]);
        if (existing['quoteId'] == quoteData['quoteId']) {
          existingIndex = i;
          break;
        }
      } catch (_) {}
    }

    quoteData["savedAt"] = DateTime.now().toIso8601String();
    if (existingIndex != -1) {
      list[existingIndex] = jsonEncode(quoteData);
    } else {
      list.add(jsonEncode(quoteData));
    }
    await prefs.setStringList("quotation_history", list);
  }

  // --- Date Picker for Validity ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntilDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: _primaryColor)),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _validUntilDate) {
      setState(() {
        _validUntilDate = picked;
      });
    }
  }

  // --- Calculations ---
  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + (item['total'] ?? 0.0));

  double get taxAmount {
    double value = double.tryParse(_taxController.text) ?? 0.0;
    return _isPercentageMode ? subtotal * (value / 100) : value;
  }

  double get discountAmount {
    double value = double.tryParse(_discountController.text) ?? 0.0;
    return _isPercentageMode ? subtotal * (value / 100) : value;
  }

  double get grandTotal => subtotal + taxAmount - discountAmount;

  // --- Item Management ---
  void _addItem() {
    if (items.length >= 20) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Limit reached")));
      return;
    }
    setState(() {
      items.add({
        'name': '',
        'partNo': '',
        'qty': 1,
        'price': 0.0,
        'purchasePrice': 0.0,
        'total': 0.0,
      });
    });
  }

  void _updateItem(int index, String field, dynamic value) {
    setState(() {
      items[index][field] = value;
      if (field == 'qty' || field == 'price') {
        int qty = items[index]['qty'] ?? 1;
        double price = items[index]['price'] ?? 0.0;
        items[index]['total'] = qty * price;
      }
    });
  }

  void _removeItem(int index) {
    setState(() => items.removeAt(index));
  }

  Future<bool> _validateItems() async {
    for (var item in items) {
      if ((item['name'] ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all item names")),
        );
        return false;
      }
      if ((item['price'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Price must be greater than 0")),
        );
        return false;
      }
    }
    return true;
  }

  // --- UI START ---
  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.card,
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
          "New Quotation",
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),

                // Client Section
                Text(
                  "CLIENT DETAILS",
                  style: GoogleFonts.inter(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCustomerSection(colors),
                const SizedBox(height: 24),

                // Items Section
                Text(
                  "ITEMS",
                  style: GoogleFonts.inter(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty) _buildEmptyState(colors),
                ...items.asMap().entries.map(
                  (e) => Column(
                    children: [
                      _buildItemCard(e.key, e.value, colors),
                      // Add Item button after each card
                      if (e.key == items.length - 1)
                        _buildAddItemButton(colors),
                    ],
                  ),
                ),
                // Show Add Item button if no items
                if (items.isEmpty) _buildAddItemButton(colors),

                const SizedBox(height: 24),

                // Calculations
                _buildCalculationsSection(colors),
                const SizedBox(height: 40),

                // Action Button
                _buildGenerateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderCard() {
    String validStr = _validUntilDate != null
        ? "${_validUntilDate!.day}/${_validUntilDate!.month}/${_validUntilDate!.year}"
        : "Select Date";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quotation No.",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quoteId,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Date Issued",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateIssued,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Validity Selector
          InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Valid Until: ",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    validStr,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, color: Colors.white54, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _customerName,
            label: "Client Name",
            icon: Icons.person_outline,
            isRequired: true,
            colors: colors,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _customerPhone,
            label: "Phone Number",
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
            colors: colors,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _customerAddress,
            label: "Billing Address",
            icon: Icons.location_on_outlined,
            maxLines: 2,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton(AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextButton.icon(
        onPressed: _addItem,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: _primaryColor.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _primaryColor.withOpacity(0.2), width: 1.5),
          ),
        ),
        icon: Icon(Icons.add_circle_outline, color: _primaryColor, size: 20),
        label: Text(
          "Add Another Item",
          style: GoogleFonts.inter(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    int index,
    Map<String, dynamic> item,
    AppColors colors,
  ) {
    return Container(
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "#${index + 1}",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: item['name'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Item Name",
                    isDense: true,
                  ),
                  onChanged: (v) => _updateItem(index, 'name', v),
                ),
              ),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSmallInput(
                  "Qty",
                  item['qty'].toString(),
                  (v) => _updateItem(index, 'qty', int.tryParse(v) ?? 1),
                  colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildSmallInput(
                  "Price",
                  item['price'].toString(),
                  (v) => _updateItem(index, 'price', double.tryParse(v) ?? 0.0),
                  colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildSmallInput(
                  "Part No",
                  item['partNo'],
                  (v) => _updateItem(index, 'partNo', v),
                  colors,
                  isNumber: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Hidden Cost Field (Optional)
          ExpansionTile(
            title: Text(
              "Total: ${item['total'].toStringAsFixed(2)}",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: _primaryColor,
                fontSize: 14,
              ),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility_off,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Purchase Cost: ",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: item['purchasePrice'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _updateItem(
                        index,
                        'purchasePrice',
                        double.tryParse(v) ?? 0.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationsSection(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Calculation Mode",
                style: GoogleFonts.inter(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              DropdownButton<bool>(
                value: _isPercentageMode,
                underline: Container(),
                icon: Icon(Icons.expand_more, color: _primaryColor),
                style: GoogleFonts.inter(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                items: const [
                  DropdownMenuItem(value: false, child: Text("Flat Amount")),
                  DropdownMenuItem(value: true, child: Text("Percentage %")),
                ],
                onChanged: (v) => setState(() => _isPercentageMode = v!),
              ),
            ],
          ),
          const Divider(height: 24),
          _summaryRow("Subtotal", subtotal.toStringAsFixed(2), colors),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInlineInput("Tax", _taxController, colors)),
              const SizedBox(width: 12),
              Text(
                taxAmount.toStringAsFixed(2),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInlineInput(
                  "Discount",
                  _discountController,
                  colors,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "-${discountAmount.toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Grand Total",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                grandTotal.toStringAsFixed(2),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            if (items.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please add at least one item")),
              );
              return;
            }
            if (!await _validateItems()) return;

            final quoteData = {
              'quoteId': quoteId,
              'date': dateIssued,
              'validUntil': _validUntilDate != null
                  ? "${_validUntilDate!.day}/${_validUntilDate!.month}/${_validUntilDate!.year}"
                  : "",
              'customerName': _customerName.text,
              'customerPhone': _customerPhone.text,
              'customerAddress': _customerAddress.text,
              'items': List<Map<String, dynamic>>.from(items),
              'subtotal': subtotal,
              'tax': taxAmount,
              'discount': discountAmount,
              'grandTotal': grandTotal,
              'status': 'Draft', // Quotes are essentially drafts/estimates
            };

            await _saveQuoteToHistory(quoteData);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuotationPreviewPage(data: quoteData),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: _primaryColor.withOpacity(0.4),
        ),
        child: Text(
          "Preview Quotation",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: colors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: colors.textSecondary),
            filled: true,
            fillColor: colors.background,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
          validator: isRequired
              ? (v) => (v == null || v.isEmpty) ? "Required" : null
              : null,
        ),
      ],
    );
  }

  Widget _buildSmallInput(
    String label,
    String val,
    Function(String) onChanged,
    AppColors colors, {
    bool isNumber = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: val,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.background,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineInput(
    String label,
    TextEditingController controller,
    AppColors colors,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: colors.textSecondary,
        ),
        filled: true,
        fillColor: colors.background,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.post_add_rounded, size: 40, color: colors.border),
            const SizedBox(height: 8),
            Text(
              "No items added yet",
              style: GoogleFonts.inter(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
