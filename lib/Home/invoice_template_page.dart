import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:EasyInvoice/Home/edit_template.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceTemplatePage extends StatefulWidget {
  final Map<String, Object> invoiceData;
  const InvoiceTemplatePage({super.key, required this.invoiceData});

  @override
  State<InvoiceTemplatePage> createState() => _InvoiceTemplatePageState();
}

class _InvoiceTemplatePageState extends State<InvoiceTemplatePage> {
  String businessName = "Company Name";
  String slogan = "Best in City";
  String adminName = "Administrator";
  String address = "";
  String contact = "";
  String businessDesc = "";

  Color headerColor = Colors.white;
  Color bgColor = Colors.white;
  Color textColor = Colors.black;
  String alignmentStr = 'left';
  bool showInvoiceLabel = true;

  String currencySymbol = '\$';
  String watermarkText = "";
  String watermarkStyle = "diagonal";
  String termsAndConditions = "";
  String nextInvoiceId = "INV-0000";

  String? _logoPath;
  bool _loaded = false;

  final Color _scaffoldBg = const Color(0xFFE2E8F0);

  final double a4Width = 595;
  final double a4Height = 842;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    businessName = prefs.getString("company_name") ?? "Company Name";
    slogan = prefs.getString("slogan") ?? "";
    adminName = prefs.getString("admin_name") ?? "Administrator";
    address = prefs.getString("company_address") ?? "";
    contact = prefs.getString("company_contact") ?? "";
    businessDesc = prefs.getString("company_desc") ?? "";
    _logoPath = prefs.getString("company_logo");

    int headerColInt = prefs.getInt("header_color") ?? 0xFFFFFFFF;
    int bgColInt = prefs.getInt("bg_color") ?? 0xFFFFFFFF;
    int textColInt = prefs.getInt("text_color") ?? 0xFF000000;
    alignmentStr = prefs.getString("company_align") ?? "left";
    showInvoiceLabel = prefs.getBool("show_invoice_label") ?? true;

    currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    watermarkText = prefs.getString('watermark_text') ?? "";
    watermarkStyle = prefs.getString('watermark_style') ?? "diagonal";
    termsAndConditions = prefs.getString('invoice_policy') ?? "";

    String startSeqStr = prefs.getString('invoice_sequence') ?? "0000";
    nextInvoiceId = "INV-$startSeqStr";

    headerColor = Color(headerColInt);
    bgColor = Color(bgColInt);
    textColor = Color(textColInt);

    setState(() => _loaded = true);
  }

  Future<void> _openEditPage() async {
    if (!mounted) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditTemplatePage(data: {})),
    );
    if (updated == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Preview",
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openEditPage,
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.edit, color: Colors.black87, size: 20),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.1,
        maxScale: 4.0,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Container(
                width: a4Width,
                height: a4Height,
                color: bgColor,
                child: Stack(
                  children: [
                    if (watermarkText.isNotEmpty)
                      Positioned.fill(child: _buildWatermark()),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            child: Column(
                              children: [
                                _buildInvoiceMeta(),
                                const SizedBox(height: 10),
                                _buildTableHeader(),
                                _buildGhostTable(),
                                const SizedBox(height: 8),
                                _buildTotals(),
                                const Spacer(),
                                _buildFooter(),
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
          ),
        ),
      ),
    );
  }

  Widget _buildWatermark() {
    double angle = watermarkStyle == 'diagonal' ? -pi / 4 : 0;
    double baseFontSize = 50;
    double fontSize = watermarkStyle == 'diagonal'
        ? baseFontSize * 1.01
        : baseFontSize * 0.97;
    String text = watermarkText.toUpperCase();
    List<String> lines = [];
    for (int i = 0; i < text.length; i += 15) {
      lines.add(text.substring(i, i + 15 > text.length ? text.length : i + 15));
    }
    return Center(
      child: Padding(
        padding: watermarkStyle == 'diagonal'
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 20),
        child: Transform.rotate(
          angle: angle,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: lines
                  .map(
                    (line) => Text(
                      line,
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        color: textColor.withOpacity(0.04),
                        letterSpacing: 10,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color headerTxtCol = headerColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    ImageProvider? logoImage;
    if (_logoPath != null) {
      if (kIsWeb) {
        logoImage = NetworkImage(_logoPath!);
      } else if (File(_logoPath!).existsSync()) {
        logoImage = FileImage(File(_logoPath!));
      }
    }

    return Container(
      width: double.infinity,
      height: 140,
      color: headerColor,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logoImage != null)
            Container(
              margin: const EdgeInsets.only(right: 15),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                image: DecorationImage(image: logoImage, fit: BoxFit.cover),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: alignmentStr == 'right'
                  ? CrossAxisAlignment.end
                  : (alignmentStr == 'center'
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start),
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    businessName,
                    style: GoogleFonts.inter(
                      color: headerTxtCol,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (slogan.isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      slogan,
                      style: GoogleFonts.inter(
                        color: headerTxtCol.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (businessDesc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        businessDesc,
                        style: GoogleFonts.inter(
                          color: headerTxtCol.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                if (address.isNotEmpty)
                  _headerIconText(Icons.location_on, address, headerTxtCol),
                if (contact.isNotEmpty)
                  _headerIconText(Icons.phone, contact, headerTxtCol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconText(IconData icon, String text, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.inter(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildInvoiceMeta() {
    String customerName =
        widget.invoiceData['customerName']?.toString() ?? "Client Name";
    if (customerName.isEmpty) customerName = "Client Name";

    String customerAddress =
        widget.invoiceData['customerAddress']?.toString() ?? "Client Address";
    if (customerAddress.isEmpty) customerAddress = "";

    String customerContact =
        widget.invoiceData['customerContact']?.toString() ?? "Contact Info";
    if (customerContact.isEmpty) customerContact = "";

    String paymentType =
        widget.invoiceData['paymentType']?.toString() ?? "Cash Sale";

    return SizedBox(
      height: 75,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "BILL TO",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    customerName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (customerAddress.isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      customerAddress,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                if (customerContact.isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      customerContact,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showInvoiceLabel)
                  Text(
                    "INVOICE",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: headerColor.withOpacity(0.45),
                    ),
                  ),
                _metaRow("Type:", paymentType),
                _metaRow("Invoice No:", nextInvoiceId),
                _metaRow(
                  "Date:",
                  widget.invoiceData['invoiceDate']?.toString() ?? "24/01/2026",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
        const SizedBox(width: 5),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    Color headerRowTextColor = headerColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
                child: Text(
                  "S.No",
                  style: _tableHeaderStyle(headerRowTextColor),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                alignment: Alignment.centerLeft,
                child: Text(
                  "ITEM DESCRIPTION",
                  style: _tableHeaderStyle(headerRowTextColor),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
                child: Text(
                  "QTY",
                  style: _tableHeaderStyle(headerRowTextColor),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                alignment: Alignment.centerRight,
                child: Text(
                  "PRICE",
                  style: _tableHeaderStyle(headerRowTextColor),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                alignment: Alignment.centerRight,
                child: Text(
                  "TOTAL",
                  style: _tableHeaderStyle(headerRowTextColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyle(Color color) =>
      GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color);

  Widget _buildGhostTable() {
    List items = (widget.invoiceData['items'] as List?) ?? [];
    return Column(
      children: List.generate(10, (index) {
        if (index < items.length) {
          final item = items[index];
          return _tableRow(
            (index + 1).toString(),
            item['name'].toString(),
            item['qty'].toString(),
            item['price'].toString(),
          );
        } else {
          return _tableRow("", "", "", "");
        }
      }),
    );
  }

  Widget _tableRow(String sNo, String name, String qty, String price) {
    double qtyNum = double.tryParse(qty) ?? 0;
    double priceNum = double.tryParse(price) ?? 0;
    double total = qtyNum * priceNum;
    bool isEmpty = name.isEmpty && qty.isEmpty && price.isEmpty;

    return Container(
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              child: Text(
                isEmpty ? '' : '$sNo.',
                style: GoogleFonts.inter(fontSize: 10, color: textColor),
              ),
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey.shade200),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerLeft,
              child: isEmpty
                  ? Container()
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: textColor,
                        ),
                      ),
                    ),
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey.shade200),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              child: isEmpty
                  ? Container()
                  : Text(
                      qty,
                      style: GoogleFonts.inter(fontSize: 10, color: textColor),
                    ),
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey.shade200),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerRight,
              child: isEmpty
                  ? Container()
                  : Text(
                      "$currencySymbol${priceNum.toStringAsFixed(0)}",
                      style: GoogleFonts.inter(fontSize: 10, color: textColor),
                    ),
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey.shade200),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerRight,
              child: isEmpty
                  ? Container()
                  : Text(
                      "$currencySymbol${total.toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    double sub =
        double.tryParse(widget.invoiceData['subtotal']?.toString() ?? "0") ?? 0;
    double tax =
        double.tryParse(widget.invoiceData['tax']?.toString() ?? "0") ?? 0;
    double discount =
        double.tryParse(widget.invoiceData['discount']?.toString() ?? "0") ?? 0;
    double grand =
        double.tryParse(widget.invoiceData['grandTotal']?.toString() ?? "0") ??
        0;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _totalRow("Subtotal", sub),
            if (tax > 0) _totalRow("Tax", tax),
            if (discount > 0) _totalRow("Discount", discount, isNegative: true),
            Divider(color: Colors.grey.shade300, height: 8),
            _totalRow("Total", grand, isGrand: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(
    String label,
    double value, {
    bool isGrand = false,
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isGrand ? 12 : 10,
              fontWeight: isGrand ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          Text(
            "${isNegative ? '-' : ''}$currencySymbol${value.toStringAsFixed(2)}",
            style: GoogleFonts.inter(
              fontSize: isGrand ? 12 : 10,
              fontWeight: isGrand ? FontWeight.bold : FontWeight.normal,
              color: isGrand ? headerColor : textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  Container(width: 120, height: 1, color: Colors.black45),
                  const SizedBox(height: 2),
                  Text(
                    "Receiver Signature",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      adminName,
                      style: GoogleFonts.dancingScript(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    "Authorized Signatory",
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (termsAndConditions.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(6),
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: headerColor, width: 3)),
              color: Colors.grey.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Additional Info:",
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    termsAndConditions,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: textColor.withOpacity(0.7),
                      height: 1.1,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 5),
        Text(
          "Thank you for your business!",
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
