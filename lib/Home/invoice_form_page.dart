import 'package:EasyInvoice/Home/edit_template.dart';
import 'package:EasyInvoice/Home/template_preview.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Add this import

class InvoiceFormPage extends StatefulWidget {
  const InvoiceFormPage({super.key});

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

  List<Map<String, dynamic>> items = [];
  String invoiceId = "";
  String invoiceDate = "";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color _primaryColor = const Color(0xFF0F1C2E);
  final Color _secondaryColor = const Color(0xFF0D47A1);
  final Color _accentColor = const Color(0xFF2A4B7C);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1A1A1A);
  final Color _textSecondary = const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _generateInvoiceDetails();
    _checkTemplateDialog();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // NEW METHOD: Save invoice to history
  Future<void> _saveInvoiceToHistory(Map<String, dynamic> invoiceData) async {
    final prefs = await SharedPreferences.getInstance();

    // Load existing history
    final list = prefs.getStringList("invoice_history") ?? [];

    // Check if invoice already exists
    bool exists = list.any((item) {
      try {
        final existing = jsonDecode(item);
        return existing['invoiceId'] == invoiceData['invoiceId'];
      } catch (e) {
        return false;
      }
    });

    if (exists) {
      // Invoice already exists, don't save duplicate
      return;
    }

    // Add creation timestamp
    invoiceData["savedAt"] = DateTime.now().toIso8601String();

    // Save to history
    list.add(jsonEncode(invoiceData));
    await prefs.setStringList("invoice_history", list);

    print('Invoice saved to history: ${invoiceData['invoiceId']}');
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
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, _primaryColor.withOpacity(0.95)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _secondaryColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _secondaryColor.withOpacity(0.2),
                          _secondaryColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      size: 60,
                      color: _secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Premium Template Available",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Customize your invoice template to match your brand's luxury aesthetic and create professional, stunning invoices.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassButton(
                          text: "Later",
                          onPressed: () => Navigator.pop(context),
                          isSecondary: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGlassButton(
                          text: "Customize Now",
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EditTemplatePage(data: {}),
                              ),
                            ).then((_) => _animationController.forward());
                          },
                          gradient: LinearGradient(
                            colors: [_secondaryColor, const Color(0xFFD4AF37)],
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
      },
    );
  }

  void _generateInvoiceDetails() {
    setState(() {
      invoiceId =
          "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
      invoiceDate =
          "${DateTime.now().day.toString().padLeft(2, '0')}/"
          "${DateTime.now().month.toString().padLeft(2, '0')}/"
          "${DateTime.now().year}";
    });
  }

  void _addItem() {
    setState(() {
      items.add({'name': '', 'qty': 1, 'price': 0.0, 'total': 0.0});
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

  double get taxAmount => double.tryParse(_taxController.text) ?? 0.0;
  double get discountAmount => double.tryParse(_discountController.text) ?? 0.0;

  double get grandTotal => subtotal + taxAmount - discountAmount;

  bool _validateItems() {
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
        _showPremiumSnack("Price must be greater than 0");
        return false;
      }
    }
    return true;
  }

  void _showPremiumSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _primaryColor,
        elevation: 10,
      ),
    );
  }

  Widget _buildGlassButton({
    required String text,
    required VoidCallback onPressed,
    bool isSecondary = false,
    LinearGradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient:
            gradient ??
            (isSecondary
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  )
                : LinearGradient(colors: [_accentColor, _primaryColor])),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isSecondary ? Colors.white : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundColor, const Color(0xFFE8EEF5)],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _fadeAnimation.value) * 20),
                  child: child,
                ),
              );
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 150,
                  floating: false,
                  pinned: true,
                  backgroundColor: _primaryColor,
                  elevation: 0,
                  shape: const ContinuousRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        'Create Invoice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor,
                            _primaryColor.withOpacity(0.9),
                            _accentColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -100,
                            top: -50,
                            child: Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _secondaryColor.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -50,
                            bottom: -50,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _secondaryColor.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInvoiceHeader(),

                          const SizedBox(height: 24),

                          _buildCustomerDetails(),

                          const SizedBox(height: 24),

                          _buildProductsSection(),

                          const SizedBox(height: 24),

                          _buildTaxDiscountCard(),

                          const SizedBox(height: 24),

                          _buildSummaryCard(),

                          const SizedBox(height: 40),

                          // MODIFIED: Updated Generate Invoice button
                          _buildGenerateButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVOICE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    invoiceId,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date:',
                        style: TextStyle(fontSize: 14, color: _textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        invoiceDate,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _secondaryColor.withOpacity(0.1),
                    _secondaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _secondaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: _secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        _secondaryColor,
                        _secondaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildPremiumField(
              controller: _customerName,
              label: "Customer Name *",
              icon: Icons.person_outline_rounded,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildPremiumField(
              controller: _customerPhone,
              label: "Phone Number",
              icon: Icons.phone_iphone_rounded,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildPremiumField(
              controller: _customerAddress,
              label: "Address",
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _secondaryColor,
                    const Color.fromARGB(255, 94, 166, 229),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _secondaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _addItem,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 60,
                  color: _textSecondary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No products added',
                  style: TextStyle(fontSize: 16, color: _textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add at least one product to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ...items.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return _buildProductItem(index, item);
        }).toList(),
      ],
    );
  }

  Widget _buildProductItem(int index, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withOpacity(0.1),
                        _primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shopping_bag_outlined, color: _accentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: item['name'],
                        maxLength: 30,
                        style: TextStyle(
                          fontSize: 16,
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Product Name *',
                          hintStyle: TextStyle(
                            color: _textSecondary.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (v) => _updateItem(index, 'name', v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _textSecondary.withOpacity(0.1),
                                ),
                              ),
                              child: TextFormField(
                                initialValue: item['qty'].toString(),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Qty',
                                  hintStyle: TextStyle(
                                    color: _textSecondary.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  prefixIcon: Icon(
                                    Icons.format_list_numbered_rounded,
                                    color: _textSecondary.withOpacity(0.5),
                                  ),
                                ),
                                onChanged: (v) => _updateItem(
                                  index,
                                  'qty',
                                  int.tryParse(v) ?? 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _textSecondary.withOpacity(0.1),
                                ),
                              ),
                              child: TextFormField(
                                initialValue: item['price'].toString(),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Price',
                                  hintStyle: TextStyle(
                                    color: _textSecondary.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  prefixIcon: Icon(
                                    Icons.attach_money_rounded,
                                    color: _textSecondary.withOpacity(0.5),
                                  ),
                                ),
                                onChanged: (v) => _updateItem(
                                  index,
                                  'price',
                                  double.tryParse(v) ?? 0.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Total: ',
                    style: TextStyle(fontSize: 16, color: _textSecondary),
                    children: [
                      TextSpan(
                        text: '\$${item['total'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    onPressed: () => _removeItem(index),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxDiscountCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [_accentColor, _accentColor.withOpacity(0.7)],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tax & Discount',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Tax Field (First Row) ---
            _buildPremiumField(
              controller: _taxController,
              label: "Tax Amount",
              icon: Icons.account_balance_outlined,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 10),
            _buildPremiumField(
              controller: _discountController,
              label: "Discount",
              icon: Icons.discount_outlined,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }

  //summary card
  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor.withOpacity(0.05),
            _accentColor.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: _secondaryColor.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSummaryRow("Subtotal", subtotal),
            if (taxAmount > 0) _buildSummaryRow("Tax", taxAmount),
            if (discountAmount > 0)
              _buildSummaryRow("Discount", -discountAmount),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _secondaryColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow("Grand Total", grandTotal, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? _textPrimary : _textSecondary,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 22 : 18,
              fontWeight: FontWeight.w700,
              color: isTotal ? _secondaryColor : _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _secondaryColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            if (_formKey.currentState!.validate()) {
              if (items.isEmpty) {
                _showPremiumSnack("Please add at least one product");
                return;
              }
              if (!_validateItems()) return;

              // Prepare invoice data
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
              };

              // Save invoice to history first
              await _saveInvoiceToHistory(invoiceData);

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invoice saved to history!',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );

              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      InvoicePreviewPage(data: invoiceData),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        var curve = Curves.easeInOutCubic;
                        var tween = Tween(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  _secondaryColor,
                  const Color.fromARGB(255, 94, 166, 229),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GENERATE INVOICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLen = 50,
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textSecondary.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        maxLength: maxLen,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: TextStyle(fontSize: 16, color: _textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textSecondary.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: _textSecondary.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          counterText: '',
          focusedBorder: InputBorder.none,
        ),
        validator: required
            ? (v) => (v == null || v.isEmpty) ? "This field is required" : null
            : null,
      ),
    );
  }
}
