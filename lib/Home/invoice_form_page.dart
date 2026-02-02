import 'package:EasyInvoice/Home/invoice_template_page.dart';
import 'package:EasyInvoice/Home/template_preview.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class InvoiceFormPage extends StatefulWidget {
  final Map<String, dynamic>? editData;

  const InvoiceFormPage({super.key, this.editData});

  @override
  State<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends State<InvoiceFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _customerName = TextEditingController();
  final _customerAddress = TextEditingController();
  final _customerPhone = TextEditingController();
  final _taxController = TextEditingController();
  final _discountController = TextEditingController();

  bool _isPercentageMode = false;
  bool _isCashInvoice = true;

  List<Map<String, dynamic>> items = [];

  String invoiceId = "INV-....";
  String invoiceDate = "";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Professional Palette
  final Color _primaryColor = const Color(0xFF0F172A);
  final Color _activeColor = const Color(0xFF2563EB);

  // Status Colors
  final Color _cashColor = const Color(0xFF10B981); // Green
  final Color _creditColor = const Color(0xFFF59E0B); // Orange

  @override
  void initState() {
    super.initState();

    // Check if we're editing existing invoice
    if (widget.editData != null) {
      _loadEditData();
    } else {
      _generateInvoiceDetails();
      _checkTemplateDialog();
    }

    _loadPreferences();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- LOGIC (UNCHANGED) ---
  Future<void> _generateInvoiceDetails() async {
    setState(() {
      invoiceDate =
          "${DateTime.now().day.toString().padLeft(2, '0')}/"
          "${DateTime.now().month.toString().padLeft(2, '0')}/"
          "${DateTime.now().year}";
    });

    final prefs = await SharedPreferences.getInstance();
    String startSeqStr = prefs.getString('invoice_sequence') ?? "0000";
    int userStartInt = int.tryParse(startSeqStr) ?? 0;
    List<String> history = prefs.getStringList("invoice_history") ?? [];
    int highestHistoryId = 0;

    for (String item in history) {
      try {
        final map = jsonDecode(item);
        String savedId = map['invoiceId']?.toString() ?? "";
        String numPart = savedId.replaceAll(RegExp(r'[^0-9]'), '');
        if (numPart.isNotEmpty) {
          int val = int.tryParse(numPart) ?? 0;
          if (val > highestHistoryId) {
            highestHistoryId = val;
          }
        }
      } catch (_) {}
    }

    int baseNumber = (highestHistoryId >= userStartInt)
        ? highestHistoryId
        : userStartInt;
    int nextIdVal = baseNumber + 1;
    int minLength = startSeqStr.length;
    if (minLength < 4) minLength = 4;

    if (mounted) {
      setState(() {
        invoiceId = "INV-${nextIdVal.toString().padLeft(minLength, '0')}";
      });
    }
  }

  // Load existing invoice data for editing
  void _loadEditData() {
    if (widget.editData == null) return;

    final data = widget.editData!;

    setState(() {
      // Load basic info
      invoiceId = data['invoiceId'] ?? 'INV-....';
      invoiceDate = data['invoiceDate'] ?? '';

      // Load invoice type
      _isCashInvoice = (data['invoiceType'] ?? 'Cash') == 'Cash';

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
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPercentageMode = prefs.getBool('isPercentageMode') ?? false;
      String? savedTax = prefs.getString('savedTaxValue');
      if (savedTax != null && savedTax.isNotEmpty) {
        _taxController.text = savedTax;
      }
    });
  }

  Future<void> _updateCalculationMode(bool isPercentage) async {
    final prefs = await SharedPreferences.getInstance();
    if (_isPercentageMode != isPercentage) {
      _taxController.clear();
      _discountController.clear();
    }
    setState(() {
      _isPercentageMode = isPercentage;
    });
    await prefs.setBool('isPercentageMode', _isPercentageMode);
  }

  Future<void> _saveTaxValue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedTaxValue', _taxController.text);
  }

  Future<void> _saveInvoiceToHistory(Map<String, dynamic> invoiceData) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("invoice_history") ?? [];
    int existingIndex = -1;

    for (int i = 0; i < list.length; i++) {
      try {
        final existing = jsonDecode(list[i]);
        if (existing['invoiceId'] == invoiceData['invoiceId']) {
          existingIndex = i;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    invoiceData["savedAt"] = DateTime.now().toIso8601String();
    if (existingIndex != -1) {
      list[existingIndex] = jsonEncode(invoiceData);
    } else {
      list.add(jsonEncode(invoiceData));
    }
    await prefs.setStringList("invoice_history", list);
    await _saveTaxValue();
  }

  Future<void> _checkTemplateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    bool alreadyShown = prefs.getBool('templateDialogShown') ?? false;
    if (!alreadyShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPremiumTemplateDialog();
      });
      await prefs.setBool('templateDialogShown', true);
    }
  }

  void _showPremiumTemplateDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 32,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Professional Template",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Enhance your brand image with our premium invoice layout. Clean, professional, and fully customizable.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Maybe Later",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InvoiceTemplatePage(
                                invoiceData: {'customerName': '', 'items': []},
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Edit Now",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
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

  void _addItem() {
    if (items.length >= 8) {
      _showPremiumSnack("You can only add up to 8 items");
      return;
    }
    setState(() {
      items.insert(0, {
        'name': '',
        'partNo': '',
        'qty': 1,
        'price': 0.0,
        'purchasePrice': 0.0,
        'total': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
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

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + (item['total'] ?? 0.0));

  double get taxAmount {
    double value = double.tryParse(_taxController.text) ?? 0.0;
    if (_isPercentageMode) {
      return subtotal * (value / 100);
    }
    return value;
  }

  double get discountAmount {
    double value = double.tryParse(_discountController.text) ?? 0.0;
    if (_isPercentageMode) {
      return subtotal * (value / 100);
    }
    return value;
  }

  double get grandTotal => subtotal + taxAmount - discountAmount;

  Future<bool> _validateItemsStrictly() async {
    for (var item in items) {
      if ((item['name'] ?? '').isEmpty) {
        _showPremiumSnack("Please fill all product names");
        return false;
      }
      if ((item['qty'] ?? 0) <= 0) {
        _showPremiumSnack("Quantity must be greater than 0");
        return false;
      }
      if ((item['price'] ?? 0.0) <= 0) {
        _showPremiumSnack("Sale Price must be greater than 0");
        return false;
      }
      double purchase = item['purchasePrice'] ?? 0.0;
      if (purchase <= 0) {
        bool proceed = await _showPurchaseCostWarning();
        if (!proceed) return false;
        return true;
      }
    }
    return true;
  }

  Future<bool> _showPurchaseCostWarning() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _primaryColor,
            title: const Text(
              "Missing Purchase Cost",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "You haven't entered the purchase cost for some items.\nProfit calculations will be 0.\nProceed?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Yes, Print",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Fix it"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPremiumSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primaryColor,
      ),
    );
  }
  // --- UI START ---

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.card,
        surfaceTintColor: colors.card,
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
          "Create Invoice",
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: colors.border, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWideScreen ? 800 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card (Invoice ID & Date)
                      _buildHeaderCard(),
                      const SizedBox(height: 24),

                      // Payment Type (Cash/Credit) - NOW WITH COLORS
                      _buildPaymentTypeSelector(colors),
                      const SizedBox(height: 24),

                      // Customer Info
                      Text(
                        "BILL TO",
                        style: GoogleFonts.inter(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCustomerSection(colors),
                      const SizedBox(height: 32),

                      // Products Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "ITEMS",
                            style: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: _activeColor,
                            ),
                            label: Text(
                              "Add Item",
                              style: GoogleFonts.inter(
                                color: _activeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (items.isEmpty) _buildEmptyState(colors),
                      ...items.asMap().entries.map((entry) {
                        return _buildProductItem(
                          entry.key,
                          entry.value,
                          ObjectKey(entry.value),
                          colors,
                        );
                      }),

                      const SizedBox(height: 24),

                      // Totals & Calculations
                      _buildCalculationsSection(colors),
                      const SizedBox(height: 32),

                      // Generate Button
                      _buildGenerateButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Invoice No.",
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                invoiceId,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(height: 40, width: 1, color: Colors.white24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Date",
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                invoiceDate,
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
    );
  }

  // UPDATED: Toggle with active Colors
  Widget _buildPaymentTypeSelector(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _buildPaymentTab("Cash Sale", _isCashInvoice, _cashColor, colors),
          _buildPaymentTab(
            "Credit Sale",
            !_isCashInvoice,
            _creditColor,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTab(
    String label,
    bool isSelected,
    Color activeColor,
    AppColors colors,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isCashInvoice = (label == "Cash Sale")),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
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
          _buildModernTextField(
            controller: _customerName,
            label: "Customer Name",
            hint: "e.g. John Doe",
            icon: Icons.person_outline_rounded,
            isRequired: true,
            colors: colors,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _customerPhone,
            label: "Phone Number",
            hint: "e.g. +1 234 567 890",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            colors: colors,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _customerAddress,
            label: "Address",
            hint: "Billing address...",
            icon: Icons.location_on_outlined,
            maxLines: 2,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.post_add_rounded, size: 48, color: colors.border),
          const SizedBox(height: 12),
          Text(
            "No items added yet",
            style: GoogleFonts.inter(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Cleaner Product Item with clear labels and help text
  Widget _buildProductItem(
    int index,
    Map<String, dynamic> item,
    Key key,
    AppColors colors,
  ) {
    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
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
          children: [
            // Row 1: Item Name (Main Field)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "#${items.length - index}",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: "Enter Item Name",
                      labelText: "Item Name",
                      labelStyle: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    onChanged: (v) => _updateItem(index, 'name', v),
                  ),
                ),
                InkWell(
                  onTap: () => _removeItem(index),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Row 2: Public Fields (PartNo, Qty, Price)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildItemInput(
                    label: "Part No.",
                    hint: "Optional",
                    value: item['partNo'] ?? '',
                    onChanged: (v) => _updateItem(index, 'partNo', v),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildItemInput(
                    label: "Qty",
                    hint: "1",
                    value: item['qty'].toString(),
                    isNumber: true,
                    onChanged: (v) =>
                        _updateItem(index, 'qty', int.tryParse(v) ?? 1),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildItemInput(
                    label: "Sale Price",
                    hint: "0.00",
                    value: item['price'].toString(),
                    isNumber: true,
                    prefix: "",
                    onChanged: (v) =>
                        _updateItem(index, 'price', double.tryParse(v) ?? 0.0),
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 3: Internal Data (Hidden Cost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Purchase Cost (Hidden)",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          child: TextFormField(
                            initialValue:
                                item['purchasePrice']?.toString() ?? '0.0',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(bottom: 8),
                            ),
                            onChanged: (v) => _updateItem(
                              index,
                              'purchasePrice',
                              double.tryParse(v) ?? 0.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: colors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Line Total",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(
                        item['total'].toStringAsFixed(2),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _activeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
            children: [
              Text(
                "Calculation Mode",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<bool>(
                  value: _isPercentageMode,
                  icon: Icon(
                    Icons.expand_more_rounded,
                    color: _activeColor,
                    size: 20,
                  ),
                  style: GoogleFonts.inter(
                    color: _activeColor,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text("Percentage (%)"),
                    ),
                    DropdownMenuItem(value: false, child: Text("Flat Amount")),
                  ],
                  onChanged: (val) {
                    if (val != null) _updateCalculationMode(val);
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildCalculationRow(
            "Subtotal",
            subtotal.toStringAsFixed(2),
            false,
            colors,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInlineInput(
                  label: "Tax (${_isPercentageMode ? '%' : 'Flat'})",
                  value: _taxController.text,
                  controller: _taxController,
                  isNumber: true,
                  onChanged: (v) => setState(() {}),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                taxAmount.toStringAsFixed(2),
                style: GoogleFonts.inter(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInlineInput(
                  label: "Discount (${_isPercentageMode ? '%' : 'Flat'})",
                  value: _discountController.text,
                  controller: _discountController,
                  isNumber: true,
                  onChanged: (v) => setState(() {}),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "-${discountAmount.toStringAsFixed(2)}",
                style: GoogleFonts.inter(color: Colors.red.shade400),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildCalculationRow(
            "Grand Total",
            grandTotal.toStringAsFixed(2),
            true,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value,
    bool isBold,
    AppColors colors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? colors.textPrimary : colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? _activeColor : colors.textPrimary,
          ),
        ),
      ],
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
              _showPremiumSnack("Please add at least one product");
              return;
            }
            if (!await _validateItemsStrictly()) return;

            String status = _isCashInvoice ? 'Paid' : 'Unpaid';
            final invoiceData = {
              'customerName': _customerName.text,
              'customerPhone': _customerPhone.text,
              'customerAddress': _customerAddress.text,
              'invoiceId': invoiceId,
              'invoiceDate': invoiceDate,
              'items': List<Map<String, dynamic>>.from(items),
              'tax': taxAmount,
              'discount': discountAmount,
              'subtotal': subtotal,
              'grandTotal': grandTotal,
              'status': status,
              'invoiceType': _isCashInvoice ? 'Cash' : 'Credit',
            };
            await _saveInvoiceToHistory(invoiceData);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoicePreviewPage(
                  data: invoiceData,
                  hideAppBarActions: _isCashInvoice,
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          "Generate Invoice",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: colors.textHint),
            prefixIcon: Icon(icon, size: 20, color: colors.textSecondary),
            filled: true,
            fillColor: colors.background,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _activeColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.isEmpty) ? "Required" : null
              : null,
          onChanged: (val) => setState(() {}),
        ),
      ],
    );
  }

  // NEW: specific input helper for product items
  Widget _buildItemInput({
    required String label,
    required String hint,
    required String value,
    required Function(String) onChanged,
    bool isNumber = false,
    String? prefix,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixText: prefix,
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: colors.textHint),
            filled: true,
            fillColor: colors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _activeColor),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Legacy helper for tax/discount row
  Widget _buildInlineInput({
    required String label,
    String? value,
    TextEditingController? controller,
    required Function(String) onChanged,
    bool isNumber = false,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? value : null,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _activeColor),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
