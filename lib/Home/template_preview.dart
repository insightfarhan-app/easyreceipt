import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoicePreviewPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool hideAppBarActions;

  const InvoicePreviewPage({
    super.key,
    required this.data,
    this.hideAppBarActions = false,
  });

  @override
  State<InvoicePreviewPage> createState() => _InvoicePreviewPageState();
}

class _InvoicePreviewPageState extends State<InvoicePreviewPage> {
  late Map<String, dynamic> invoiceData;
  bool _isActionLoading = false;

  String businessName = "Company Name";
  String slogan = "Best in City";
  String adminName = "Administrator Name";
  String address = "";
  String contact = "";
  String businessDesc = "";

  Color headerColor = Colors.black;
  Color bgColor = Colors.white;
  Color textColor = Colors.black;
  String alignStr = 'left';
  bool showInvoiceLabel = true;
  String currencySymbol = '\$';
  String watermarkText = "";
  String watermarkStyle = "diagonal";
  String termsAndConditions = "";
  String finalInvoiceId = "INV-0000";
  String? _logoPath;
  bool _loaded = false;
  bool _hasPartNo = false;

  final double a4Width = 595;
  final double a4Height = 842;

  @override
  void initState() {
    super.initState();
    invoiceData = Map<String, dynamic>.from(widget.data);
    _checkPartNumber();
    _loadTemplateData();
  }

  void _checkPartNumber() {
    final items = invoiceData['items'] as List<dynamic>? ?? [];
    _hasPartNo = items.any((item) {
      final part = item['partNo']?.toString().trim();
      return part != null && part.isNotEmpty;
    });
  }

  Future<void> _loadTemplateData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    businessName = prefs.getString("company_name") ?? "Company Name";
    slogan = prefs.getString("slogan") ?? "";
    adminName = prefs.getString("admin_name") ?? "Administrator Name";
    address = prefs.getString("company_address") ?? "";
    contact = prefs.getString("company_contact") ?? "";
    businessDesc = prefs.getString("company_desc") ?? "";
    _logoPath = prefs.getString("company_logo");

    int headerColInt = prefs.getInt("header_color") ?? 0xFF000000;
    int bgColInt = prefs.getInt("bg_color") ?? 0xFFFFFFFF;
    int textColInt = prefs.getInt("text_color") ?? 0xFF000000;

    alignStr = prefs.getString("company_align") ?? "left";
    showInvoiceLabel = prefs.getBool("show_invoice_label") ?? true;
    currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    watermarkText = prefs.getString('watermark_text') ?? "";
    watermarkStyle = prefs.getString('watermark_style') ?? "diagonal";
    termsAndConditions = prefs.getString('invoice_policy') ?? "";

    String incomingId = invoiceData['invoiceId']?.toString() ?? '';
    List<String> history = prefs.getStringList("invoice_history") ?? [];
    bool isSavedInHistory = false;
    int highestHistoryId = 0;

    for (String item in history) {
      try {
        final map = jsonDecode(item);
        String savedId = map['invoiceId']?.toString() ?? "";
        if (savedId == incomingId) isSavedInHistory = true;

        String numPart = savedId.replaceAll(RegExp(r'[^0-9]'), '');
        if (numPart.isNotEmpty) {
          int val = int.tryParse(numPart) ?? 0;
          if (val > highestHistoryId) highestHistoryId = val;
        }
      } catch (_) {}
    }

    if (isSavedInHistory) {
      finalInvoiceId = incomingId;
    } else {
      String startSeqStr = prefs.getString('invoice_sequence') ?? "0000";
      if (startSeqStr.isEmpty) startSeqStr = "0000";
      int userStartInt = int.tryParse(startSeqStr) ?? 0;
      int baseNumber = (highestHistoryId >= userStartInt)
          ? highestHistoryId
          : (userStartInt - 1);
      int nextIdVal = baseNumber + 1;
      int minLength = startSeqStr.length;
      if (minLength < 4) minLength = 4;
      finalInvoiceId = "INV-${nextIdVal.toString().padLeft(minLength, '0')}";
      invoiceData['invoiceId'] = finalInvoiceId;
    }

    headerColor = Color(headerColInt);
    bgColor = Color(bgColInt);
    textColor = Color(textColInt);

    setState(() {
      _loaded = true;
    });
  }

  double _parseVal(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      if (val.trim().isEmpty) return 0.0;
      String clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, double> _calculateTotals() {
    double sub = 0.0;
    final items = (invoiceData['items'] as List?) ?? [];

    for (var item in items) {
      double qty = _parseVal(item['qty']);
      double price = _parseVal(item['price']);
      sub += (qty * price);
    }

    double tax = _parseVal(invoiceData['tax']);
    double discount = _parseVal(invoiceData['discount']);

    double grand = sub + tax - discount;
    if (grand < 0) grand = 0;

    return {"sub": sub, "tax": tax, "discount": discount, "grand": grand};
  }

  PdfColor _toPdfColor(Color color) {
    return PdfColor.fromInt(color.value);
  }

  Color _getSafeTotalColor() {
    return headerColor.computeLuminance() > 0.5 ? Colors.black : headerColor;
  }

  Future<Uint8List> _generateNativePdf() async {
    final pdf = pw.Document();

    pw.MemoryImage? profileImage;
    if (_logoPath != null && _logoPath!.isNotEmpty && !kIsWeb) {
      try {
        final file = File(_logoPath!);
        if (await file.exists()) {
          profileImage = pw.MemoryImage(await file.readAsBytes());
        }
      } catch (e) {
        debugPrint("Error loading logo for PDF: $e");
      }
    }

    final pdfHeaderColor = _toPdfColor(headerColor);
    final pdfTextColor = _toPdfColor(textColor);
    final pdfBgColor = _toPdfColor(bgColor);

    final bool isHeaderLight = headerColor.computeLuminance() > 0.5;
    final pdfSafeTotalColor = isHeaderLight ? PdfColors.black : pdfHeaderColor;

    pw.MainAxisAlignment mainAlign = pw.MainAxisAlignment.start;
    pw.CrossAxisAlignment crossAlign = pw.CrossAxisAlignment.start;
    if (alignStr == 'center') {
      mainAlign = pw.MainAxisAlignment.center;
      crossAlign = pw.CrossAxisAlignment.center;
    } else if (alignStr == 'right') {
      mainAlign = pw.MainAxisAlignment.end;
      crossAlign = pw.CrossAxisAlignment.end;
    }

    final products = invoiceData['items'] as List<dynamic>? ?? [];

    final totals = _calculateTotals();
    final subTotal = totals['sub']!;
    final tax = totals['tax']!;
    final discount = totals['discount']!;
    final grandTotal = totals['grand']!;

    String paymentType = invoiceData['paymentType']?.toString() ?? 'Cash Sale';

    List<String> headers = ['S.No'];
    if (_hasPartNo) headers.add('SKU / Item Code');
    headers.addAll(['DESCRIPTION', 'QTY', 'PRICE', 'TOTAL']);

    List<List<String>> tableData = [];
    for (int i = 0; i < 10; i++) {
      if (i < products.length) {
        final item = products[i];
        List<String> row = [];
        row.add('${i + 1}.');
        if (_hasPartNo) {
          row.add(item['partNo']?.toString() ?? '');
        }

        double qty = _parseVal(item['qty']);
        double price = _parseVal(item['price']);
        double rowTotal = qty * price;

        row.addAll([
          item['name'] ?? '',
          '${item['qty'] ?? 0}',
          price.toStringAsFixed(0),
          rowTotal.toStringAsFixed(0),
        ]);
        tableData.add(row);
      } else {
        List<String> row = [];
        row.add('');
        if (_hasPartNo) row.add('');
        row.addAll(['', '', '', '']);
        tableData.add(row);
      }
    }

    Map<int, pw.Alignment> cellAlignments = {};
    if (_hasPartNo) {
      cellAlignments = {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      };
    } else {
      cellAlignments = {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      };
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.interRegular(),
          bold: await PdfGoogleFonts.interBold(),
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: pdfBgColor,
            child: pw.Column(
              children: [
                pw.Container(
                  height: 140,
                  color: pdfHeaderColor,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (profileImage != null)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(right: 15),
                          width: 70,
                          height: 70,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(35),
                            ),
                            image: pw.DecorationImage(
                              image: profileImage,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                      pw.Expanded(
                        child: pw.Column(
                          mainAxisAlignment: mainAlign,
                          crossAxisAlignment: crossAlign,
                          children: [
                            pw.Text(
                              businessName,
                              style: pw.TextStyle(
                                color: pdfHeaderColor.luminance > 0.5
                                    ? PdfColors.black
                                    : PdfColors.white,
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            if (slogan.isNotEmpty)
                              pw.Text(
                                slogan,
                                style: pw.TextStyle(
                                  color: pdfHeaderColor.luminance > 0.5
                                      ? PdfColor(0, 0, 0, 0.8)
                                      : PdfColor(1, 1, 1, 0.8),
                                  fontSize: 12,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            if (businessDesc.isNotEmpty)
                              pw.Text(
                                businessDesc,
                                style: pw.TextStyle(
                                  color: pdfHeaderColor.luminance > 0.5
                                      ? PdfColor(0, 0, 0, 0.9)
                                      : PdfColor(1, 1, 1, 0.9),
                                  fontSize: 10,
                                ),
                              ),
                            pw.Spacer(),
                            if (address.isNotEmpty)
                              _pdfIconText(
                                address,
                                pdfHeaderColor.luminance > 0.5
                                    ? PdfColors.black
                                    : PdfColors.white,
                              ),
                            if (contact.isNotEmpty)
                              _pdfIconText(
                                contact,
                                pdfHeaderColor.luminance > 0.5
                                    ? PdfColors.black
                                    : PdfColors.white,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  "BILL TO",
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  invoiceData['customerName'] ?? 'Customer',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    color: pdfTextColor,
                                  ),
                                ),
                                if ((invoiceData['customerAddress'] ?? '')
                                    .isNotEmpty)
                                  pw.Text(
                                    invoiceData['customerAddress'],
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      color: pdfTextColor,
                                    ),
                                  ),
                                if ((invoiceData['customerPhone'] ?? '')
                                    .isNotEmpty)
                                  pw.Text(
                                    invoiceData['customerPhone'],
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      color: pdfTextColor,
                                    ),
                                  ),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                if (showInvoiceLabel)
                                  pw.Text(
                                    "INVOICE",
                                    style: pw.TextStyle(
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColor(
                                        pdfHeaderColor.red,
                                        pdfHeaderColor.green,
                                        pdfHeaderColor.blue,
                                        0.45,
                                      ),
                                    ),
                                  ),
                                _pdfMetaRow("Type:", paymentType, pdfTextColor),
                                _pdfMetaRow(
                                  "Invoice No:",
                                  finalInvoiceId,
                                  pdfTextColor,
                                ),
                                _pdfMetaRow(
                                  "Date:",
                                  invoiceData['invoiceDate'] ?? '',
                                  pdfTextColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Table.fromTextArray(
                          headers: headers,
                          data: tableData,
                          border: pw.TableBorder(
                            bottom: pw.BorderSide(color: PdfColors.grey200),
                            left: pw.BorderSide(color: PdfColors.grey200),
                            right: pw.BorderSide(color: PdfColors.grey200),
                            verticalInside: pw.BorderSide(
                              color: PdfColors.grey200,
                            ),
                            horizontalInside: pw.BorderSide(
                              color: PdfColors.grey200,
                            ),
                          ),
                          headerStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: pdfTextColor,
                            fontSize: 9,
                          ),
                          headerDecoration: pw.BoxDecoration(
                            color: PdfColor(
                              pdfHeaderColor.red,
                              pdfHeaderColor.green,
                              pdfHeaderColor.blue,
                              0.08,
                            ),
                          ),
                          cellHeight: 26,
                          cellAlignments: cellAlignments,
                          cellStyle: pw.TextStyle(
                            fontSize: 10,
                            color: pdfTextColor,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Container(
                            width: 200,
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey50,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                              border: pw.Border.all(color: PdfColors.grey200),
                            ),
                            child: pw.Column(
                              children: [
                                _pdfTotalRow(
                                  "Subtotal",
                                  subTotal,
                                  currencySymbol,
                                  pdfTextColor,
                                ),
                                if (tax > 0)
                                  _pdfTotalRow(
                                    "Tax",
                                    tax,
                                    currencySymbol,
                                    pdfTextColor,
                                  ),
                                if (discount > 0)
                                  _pdfTotalRow(
                                    "Discount",
                                    discount,
                                    currencySymbol,
                                    pdfTextColor,
                                    isNegative: true,
                                  ),
                                pw.Divider(color: PdfColors.grey300),
                                _pdfTotalRow(
                                  "Total",
                                  grandTotal,
                                  currencySymbol,
                                  pdfTextColor,
                                  isGrand: true,
                                  grandColor: pdfSafeTotalColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.Spacer(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Column(
                              children: [
                                pw.Container(
                                  width: 120,
                                  height: 1,
                                  color: PdfColors.black,
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  "Receiver Signature",
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: pdfTextColor,
                                  ),
                                ),
                              ],
                            ),
                            pw.Column(
                              children: [
                                pw.Container(
                                  width: 120,
                                  height: 1,
                                  color: PdfColors.black,
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  adminName,
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    color: pdfTextColor,
                                  ),
                                ),
                                pw.Text(
                                  "Authorized Signatory",
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        if (termsAndConditions.isNotEmpty)
                          pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            width: double.infinity,
                            height: 45,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                left: pw.BorderSide(
                                  color: pdfHeaderColor,
                                  width: 3,
                                ),
                              ),
                              color: PdfColors.grey50,
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  "Terms & Conditions",
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: pdfTextColor,
                                  ),
                                ),
                                pw.Text(
                                  termsAndConditions,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: pdfTextColor,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          "Thank you for your business!",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: pdfTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfIconText(String text, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(width: 4),
        pw.Text(text, style: pw.TextStyle(color: color, fontSize: 10)),
      ],
    );
  }

  pw.Widget _pdfMetaRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfTotalRow(
    String label,
    double value,
    String sym,
    PdfColor color, {
    bool isGrand = false,
    bool isNegative = false,
    PdfColor? grandColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isGrand ? 12 : 10,
            fontWeight: isGrand ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          "${isNegative ? '-' : ''}$sym${value.toStringAsFixed(2)}",
          style: pw.TextStyle(
            fontSize: isGrand ? 12 : 10,
            fontWeight: isGrand ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isGrand ? grandColor : color,
          ),
        ),
      ],
    );
  }

  Future<void> _printInvoiceHD() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      final Uint8List pdfBytes = await _generateNativePdf();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Invoice_$finalInvoiceId',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Printing failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _shareAsPdf() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      final Uint8List pdfBytes = await _generateNativePdf();
      final tempDir = await getTemporaryDirectory();
      final file = File("${tempDir.path}/Invoice_$finalInvoiceId.pdf");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: "Here is your invoice from $businessName");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showShareOptions() {
    _shareAsPdf();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          "Invoice Preview",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F2027),
                    Color(0xFF203A43),
                    Color(0xFF2C5364),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
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
                                  Positioned.fill(
                                    child: _buildWatermarkScreen(),
                                  ),
                                Column(
                                  children: [
                                    _buildHeaderScreen(),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 30,
                                          vertical: 15,
                                        ),
                                        child: Column(
                                          children: [
                                            _buildInvoiceMetaScreen(),
                                            const SizedBox(height: 10),
                                            _buildTableHeaderScreen(),
                                            _buildGhostTableScreen(),
                                            const SizedBox(height: 8),
                                            _buildTotalsScreen(),
                                            const Spacer(),
                                            _buildFooterScreen(),
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
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black26,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isActionLoading
                              ? null
                              : _showShareOptions,
                          icon: const Icon(Icons.share),
                          label: const Text("Share"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isActionLoading ? null : _printInvoiceHD,
                          icon: const Icon(Icons.print),
                          label: const Text("Print"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermarkScreen() {
    double angle = watermarkStyle == 'diagonal' ? -pi / 4 : 0;
    double baseFontSize = 80;
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
            : const EdgeInsets.symmetric(horizontal: 30),
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

  Widget _buildHeaderScreen() {
    Color headerTxtCol = headerColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    ImageProvider? logoImage;
    if (_logoPath != null && _logoPath!.isNotEmpty) {
      if (kIsWeb) {
        logoImage = NetworkImage(_logoPath!);
      } else if (File(_logoPath!).existsSync())
        logoImage = FileImage(File(_logoPath!));
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
              crossAxisAlignment: alignStr == 'right'
                  ? CrossAxisAlignment.end
                  : (alignStr == 'center'
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
                  _headerIconTextScreen(
                    Icons.location_on,
                    address,
                    headerTxtCol,
                  ),
                if (contact.isNotEmpty)
                  _headerIconTextScreen(Icons.phone, contact, headerTxtCol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconTextScreen(IconData icon, String text, Color color) {
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

  Widget _buildInvoiceMetaScreen() {
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
                    invoiceData['customerName'] ?? 'Customer',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if ((invoiceData['customerAddress'] ?? '').isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      invoiceData['customerAddress'],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                if ((invoiceData['customerPhone'] ?? '').isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      invoiceData['customerPhone'],
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
                _metaRowScreen(
                  "Type:",
                  invoiceData['paymentType']?.toString() ?? 'Cash Sale',
                ),
                _metaRowScreen("Invoice No:", finalInvoiceId),
                _metaRowScreen("Date:", invoiceData['invoiceDate'] ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRowScreen(String label, String value) {
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

  Widget _buildTableHeaderScreen() {
    // Determine the label color based on header background brightness
    Color headerRowLabelColor = headerColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: headerColor, // Changed to match exact header background color
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
                  style: _tableHeaderStyleScreen(headerRowLabelColor),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            if (_hasPartNo) ...[
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "SKU / Item Code",
                    style: _tableHeaderStyleScreen(headerRowLabelColor),
                  ),
                ),
              ),
              VerticalDivider(width: 1, color: Colors.grey.shade300),
            ],
            Expanded(
              flex: _hasPartNo ? 3 : 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                alignment: Alignment.centerLeft,
                child: Text(
                  "DESCRIPTION",
                  style: _tableHeaderStyleScreen(headerRowLabelColor),
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
                  style: _tableHeaderStyleScreen(headerRowLabelColor),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            Expanded(
              flex: _hasPartNo ? 1 : 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                alignment: Alignment.centerRight,
                child: Text(
                  "PRICE",
                  style: _tableHeaderStyleScreen(headerRowLabelColor),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade300),
            Expanded(
              flex: _hasPartNo ? 1 : 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                alignment: Alignment.centerRight,
                child: Text(
                  "TOTAL",
                  style: _tableHeaderStyleScreen(headerRowLabelColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyleScreen(Color color) => GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: color, // Use the dynamic label color
  );

  Widget _buildGhostTableScreen() {
    List items = (invoiceData['items'] as List?) ?? [];
    return Column(
      children: List.generate(10, (index) {
        if (index < items.length) {
          final item = items[index];
          return _tableRowScreen(
            (index + 1).toString(),
            item['name'].toString(),
            item['partNo']?.toString(),
            item['qty'].toString(),
            item['price'].toString(),
          );
        } else {
          return _tableRowScreen("", "", "", "", "");
        }
      }),
    );
  }

  Widget _tableRowScreen(
    String sNo,
    String name,
    String? partNo,
    String qty,
    String price,
  ) {
    double qtyNum = _parseVal(qty);
    double priceNum = _parseVal(price);
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
          if (_hasPartNo) ...[
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.centerLeft,
                child: isEmpty
                    ? Container()
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          partNo ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: textColor,
                          ),
                        ),
                      ),
              ),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade200),
          ],
          Expanded(
            flex: _hasPartNo ? 3 : 4,
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
            flex: _hasPartNo ? 1 : 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerRight,
              child: isEmpty
                  ? Container()
                  : Text(
                      priceNum.toStringAsFixed(0),
                      style: GoogleFonts.inter(fontSize: 10, color: textColor),
                    ),
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey.shade200),
          Expanded(
            flex: _hasPartNo ? 1 : 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerRight,
              child: isEmpty
                  ? Container()
                  : Text(
                      total.toStringAsFixed(0),
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

  Widget _buildTotalsScreen() {
    final totals = _calculateTotals();

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
            _totalRowScreen("Subtotal", totals['sub']!),
            if (totals['tax']! > 0) _totalRowScreen("Tax", totals['tax']!),
            if (totals['discount']! > 0)
              _totalRowScreen(
                "Discount",
                totals['discount']!,
                isNegative: true,
              ),
            Divider(color: Colors.grey.shade300, height: 8),
            _totalRowScreen("Total", totals['grand']!, isGrand: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRowScreen(
    String label,
    double value, {
    bool isGrand = false,
    bool isNegative = false,
  }) {
    Color safeGrandColor = _getSafeTotalColor();

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
              color: isGrand ? safeGrandColor : textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                Expanded(
                  child: Text(
                    termsAndConditions,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: textColor.withOpacity(0.7),
                      height: 1.1,
                    ),
                    maxLines: 2,
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
