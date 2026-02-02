import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:google_fonts/google_fonts.dart';

class QuotationPreviewPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool hideAppBarActions;

  const QuotationPreviewPage({
    super.key,
    required this.data,
    this.hideAppBarActions = false,
  });

  @override
  State<QuotationPreviewPage> createState() => _QuotationPreviewPageState();
}

class _QuotationPreviewPageState extends State<QuotationPreviewPage> {
  late Map<String, dynamic> quoteData;
  bool _isActionLoading = false;

  // Company Details
  String businessName = "Your Company";
  String slogan = "Excellence in Service";
  String adminName = "Admin";
  String address = "";
  String contact = "";
  String businessDesc = "";

  // Styling
  Color headerColor = const Color(0xFF1E40AF); // Professional Navy Blue
  Color bgColor = Colors.white;
  Color textColor = Colors.black;
  String alignStr = 'left';
  bool showLabel = true;
  String currencySymbol = '\$';
  String watermarkText = "";
  String watermarkStyle = "diagonal";
  String termsAndConditions = "This quotation is valid for 15 days.";

  // Logic
  String finalQuoteId = "QTN-0000";
  String validUntilDate = "";
  String? _logoPath;
  bool _loaded = false;
  bool _hasPartNo = false;

  // Pagination
  static const int ITEMS_PER_PAGE = 12;
  static const int MAX_ITEMS = 24;

  final double a4Width = 595;
  final double a4Height = 842;

  @override
  void initState() {
    super.initState();
    quoteData = Map<String, dynamic>.from(widget.data);
    _checkPartNumber();
    _calculateValidity();
    _loadTemplateData();
  }

  void _checkPartNumber() {
    final items = quoteData['items'] as List<dynamic>? ?? [];
    _hasPartNo = items.any((item) {
      final part = item['partNo']?.toString().trim();
      return part != null && part.isNotEmpty;
    });

    // Validate item limit
    if (items.length > MAX_ITEMS) {
      debugPrint(
        "WARNING: Total items (${items.length}) exceeds maximum limit of $MAX_ITEMS. Truncating to $MAX_ITEMS items.",
      );
      quoteData['items'] = items.sublist(0, MAX_ITEMS);
    }
  }

  void _calculateValidity() {
    // If quote date exists, add 15 days for validity, or use provided validUntil
    if (quoteData['validUntil'] != null) {
      validUntilDate = quoteData['validUntil'];
    } else {
      // Simple logic to just show the text in footer if date calc is complex without intl package
      // For now, we leave it empty and let the Terms & Conditions handle "Valid for X days"
      validUntilDate = "";
    }
  }

  Future<void> _loadTemplateData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    businessName = prefs.getString("company_name") ?? "Your Company";
    slogan = prefs.getString("slogan") ?? "";
    adminName = prefs.getString("admin_name") ?? "Administrator";
    address = prefs.getString("company_address") ?? "";
    contact = prefs.getString("company_contact") ?? "";
    businessDesc = prefs.getString("company_desc") ?? "";
    _logoPath = prefs.getString("company_logo");

    int headerColInt = prefs.getInt("header_color") ?? 0xFF1E40AF;
    int bgColInt = prefs.getInt("bg_color") ?? 0xFFFFFFFF;
    int textColInt = prefs.getInt("text_color") ?? 0xFF000000;

    alignStr = prefs.getString("company_align") ?? "left";
    showLabel = prefs.getBool("show_invoice_label") ?? true;
    currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    watermarkText = prefs.getString('watermark_text') ?? "QUOTATION";
    watermarkStyle = prefs.getString('watermark_style') ?? "diagonal";
    termsAndConditions = prefs.getString('invoice_policy') ?? "";

    // --- ID GENERATION LOGIC (Specific to Quotations) ---
    String incomingId = quoteData['quoteId']?.toString() ?? '';
    List<String> history = prefs.getStringList("quotation_history") ?? [];
    bool isSavedInHistory = false;
    int highestHistoryId = 0;

    for (String item in history) {
      try {
        final map = jsonDecode(item);
        String savedId = map['quoteId']?.toString() ?? "";
        if (savedId == incomingId) isSavedInHistory = true;

        String numPart = savedId.replaceAll(RegExp(r'[^0-9]'), '');
        if (numPart.isNotEmpty) {
          int val = int.tryParse(numPart) ?? 0;
          if (val > highestHistoryId) highestHistoryId = val;
        }
      } catch (_) {}
    }

    if (isSavedInHistory) {
      finalQuoteId = incomingId;
    } else {
      String startSeqStr = prefs.getString('quotation_sequence') ?? "0000";
      if (startSeqStr.isEmpty) startSeqStr = "0000";
      int userStartInt = int.tryParse(startSeqStr) ?? 0;
      int baseNumber = (highestHistoryId >= userStartInt)
          ? highestHistoryId
          : (userStartInt - 1);
      int nextIdVal = baseNumber + 1;
      int minLength = startSeqStr.length;
      if (minLength < 4) minLength = 4;
      finalQuoteId = "QTN-${nextIdVal.toString().padLeft(minLength, '0')}";
      quoteData['quoteId'] = finalQuoteId;
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
    final items = (quoteData['items'] as List?) ?? [];

    for (var item in items) {
      double qty = _parseVal(item['qty']);
      double price = _parseVal(item['price']);
      sub += (qty * price);
    }

    double tax = _parseVal(quoteData['tax']);
    double discount = _parseVal(quoteData['discount']);

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

  // Helper method to get total pages
  int _getTotalPages() {
    final items = quoteData['items'] as List<dynamic>? ?? [];
    return (items.length > ITEMS_PER_PAGE) ? 2 : 1;
  }

  // Build all pages for preview
  List<Widget> _buildAllPages() {
    final items = quoteData['items'] as List<dynamic>? ?? [];
    final int totalPages = _getTotalPages();
    List<Widget> pages = [];

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      pages.add(_buildSinglePage(pageNum, totalPages));
      // Add spacing between pages
      if (pageNum < totalPages - 1) {
        pages.add(const SizedBox(width: 30));
      }
    }

    return pages;
  }

  // Build a single page preview
  Widget _buildSinglePage(int pageNum, int totalPages) {
    final items = quoteData['items'] as List<dynamic>? ?? [];
    final int startIndex = pageNum * ITEMS_PER_PAGE;
    final int endIndex = ((pageNum + 1) * ITEMS_PER_PAGE > items.length)
        ? items.length
        : (pageNum + 1) * ITEMS_PER_PAGE;

    return FittedBox(
      child: Container(
        width: a4Width,
        height: a4Height,
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (watermarkText.isNotEmpty)
              Positioned.fill(child: _buildScreenWatermark()),
            Column(
              children: [
                _buildScreenHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        _buildScreenMeta(
                          pageNum: pageNum + 1,
                          totalPages: totalPages,
                        ),
                        const SizedBox(height: 20),
                        _buildScreenTableHeaders(),
                        _buildScreenTableRows(
                          startIndex: startIndex,
                          endIndex: endIndex,
                        ),
                        const SizedBox(height: 10),
                        // Only show totals on last page
                        if (pageNum == totalPages - 1) _buildScreenTotals(),
                        const Spacer(),
                        // Only show footer on last page
                        if (pageNum == totalPages - 1) _buildScreenFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= PDF GENERATION =================
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

    final products = quoteData['items'] as List<dynamic>? ?? [];
    final totals = _calculateTotals();

    // Calculate number of pages needed
    final int totalPages = (products.length > ITEMS_PER_PAGE) ? 2 : 1;

    // Add pages
    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      final int startIndex = pageNum * ITEMS_PER_PAGE;
      final int endIndex = ((pageNum + 1) * ITEMS_PER_PAGE > products.length)
          ? products.length
          : (pageNum + 1) * ITEMS_PER_PAGE;

      pdf.addPage(
        await _buildPdfPage(
          profileImage,
          pdfHeaderColor,
          pdfTextColor,
          pdfBgColor,
          isHeaderLight,
          pdfSafeTotalColor,
          mainAlign,
          crossAlign,
          products,
          totals,
          startIndex,
          endIndex,
          pageNum + 1,
          totalPages,
        ),
      );
    }

    return pdf.save();
  }

  // Build a single PDF page
  Future<pw.Page> _buildPdfPage(
    pw.MemoryImage? profileImage,
    PdfColor pdfHeaderColor,
    PdfColor pdfTextColor,
    PdfColor pdfBgColor,
    bool isHeaderLight,
    PdfColor pdfSafeTotalColor,
    pw.MainAxisAlignment mainAlign,
    pw.CrossAxisAlignment crossAlign,
    List<dynamic> products,
    Map<String, double> totals,
    int startIndex,
    int endIndex,
    int pageNum,
    int totalPages,
  ) async {
    // Setup Headers - Hide Part No in PDF for quotations
    List<String> headers = ['S.No'];
    headers.addAll(['DESCRIPTION', 'QTY', 'UNIT PRICE', 'TOTAL']);

    // Setup Table Data for this page
    List<List<String>> tableData = [];
    for (int i = 0; i < ITEMS_PER_PAGE; i++) {
      final int itemIndex = startIndex + i;
      if (itemIndex < endIndex && itemIndex < products.length) {
        final item = products[itemIndex];
        List<String> row = [];
        row.add('${itemIndex + 1}.');

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
        // Empty rows for filler
        List<String> row = [];
        row.add('');
        row.addAll(['', '', '', '']);
        tableData.add(row);
      }
    }

    // Alignment Map - Without Part No column for quotation PDF
    Map<int, pw.Alignment> cellAlignments = {};
    int colIndex = 0;
    cellAlignments[colIndex++] = pw.Alignment.center; // S.No
    cellAlignments[colIndex++] = pw.Alignment.centerLeft; // Description
    cellAlignments[colIndex++] = pw.Alignment.center; // Qty
    cellAlignments[colIndex++] = pw.Alignment.centerRight; // Price
    cellAlignments[colIndex++] = pw.Alignment.centerRight; // Total

    return pw.Page(
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
              // HEADER
              pw.Container(
                height: 130,
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
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
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
                              color: isHeaderLight
                                  ? PdfColors.black
                                  : PdfColors.white,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (slogan.isNotEmpty)
                            pw.Text(
                              slogan,
                              style: pw.TextStyle(
                                color: isHeaderLight
                                    ? PdfColors.black
                                    : PdfColors.white,
                                fontSize: 10,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          if (businessDesc.isNotEmpty)
                            pw.Text(
                              businessDesc,
                              style: pw.TextStyle(
                                color: isHeaderLight
                                    ? PdfColors.black
                                    : PdfColors.white,
                                fontSize: 9,
                              ),
                            ),
                          pw.Spacer(),
                          if (address.isNotEmpty)
                            _pdfIconText(
                              address,
                              isHeaderLight ? PdfColors.black : PdfColors.white,
                            ),
                          if (contact.isNotEmpty)
                            _pdfIconText(
                              contact,
                              isHeaderLight ? PdfColors.black : PdfColors.white,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // META INFO
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // CLIENT INFO
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "QUOTATION FOR",
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          quoteData['customerName'] ?? 'Valued Client',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: pdfTextColor,
                          ),
                        ),
                        if ((quoteData['customerAddress'] ?? '').isNotEmpty)
                          pw.Text(
                            quoteData['customerAddress'],
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: pdfTextColor,
                            ),
                          ),
                        if ((quoteData['customerPhone'] ?? '').isNotEmpty)
                          pw.Text(
                            quoteData['customerPhone'],
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: pdfTextColor,
                            ),
                          ),
                      ],
                    ),
                    // QUOTE DETAILS
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (showLabel)
                          pw.Text(
                            "QUOTATION",
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor(
                                pdfHeaderColor.red,
                                pdfHeaderColor.green,
                                pdfHeaderColor.blue,
                                0.5,
                              ),
                            ),
                          ),
                        _pdfMetaRow(
                          "Quotation No:",
                          finalQuoteId,
                          pdfTextColor,
                        ),
                        _pdfMetaRow(
                          "Date:",
                          quoteData['date'] ??
                              DateTime.now().toString().split(' ')[0],
                          pdfTextColor,
                        ),
                        if (validUntilDate.isNotEmpty)
                          _pdfMetaRow(
                            "Valid Until:",
                            validUntilDate,
                            PdfColors.redAccent,
                          ),
                        // Page number indicator if multi-page
                        if (totalPages > 1)
                          pw.Text(
                            "Page $pageNum of $totalPages",
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // TABLE
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 30),
                child: pw.Table.fromTextArray(
                  headers: headers,
                  data: tableData,
                  border: pw.TableBorder.all(
                    color: PdfColors.grey200,
                    width: 0.5,
                  ),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: pdfTextColor,
                    fontSize: 9,
                  ),
                  headerDecoration: pw.BoxDecoration(color: pdfHeaderColor),
                  cellHeight: 24,
                  cellAlignments: cellAlignments,
                  cellStyle: pw.TextStyle(fontSize: 10, color: pdfTextColor),
                ),
              ),

              // TOTALS - Only show on last page
              if (pageNum == totalPages)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 200,
                        padding: const pw.EdgeInsets.all(10),
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
                              totals['sub']!,
                              currencySymbol,
                              pdfTextColor,
                            ),
                            if (totals['tax']! > 0)
                              _pdfTotalRow(
                                "Tax",
                                totals['tax']!,
                                currencySymbol,
                                pdfTextColor,
                              ),
                            if (totals['discount']! > 0)
                              _pdfTotalRow(
                                "Discount",
                                totals['discount']!,
                                currencySymbol,
                                pdfTextColor,
                                isNegative: true,
                              ),
                            pw.Divider(color: PdfColors.grey300),
                            _pdfTotalRow(
                              "Grand Total",
                              totals['grand']!,
                              currencySymbol,
                              pdfTextColor,
                              isGrand: true,
                              grandColor: pdfSafeTotalColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              pw.Spacer(),

              // FOOTER / TERMS - Only on last page
              if (pageNum == totalPages)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Receiver Signature (Left Side)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 100,
                            height: 1,
                            color: PdfColors.grey400,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Receiver Signature",
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: pdfTextColor,
                            ),
                          ),
                        ],
                      ),
                      // Authorized Signatory (Right Side)
                      pw.Column(
                        children: [
                          if (adminName.isNotEmpty)
                            pw.Text(
                              adminName,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          pw.Container(
                            width: 100,
                            height: 1,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Authorized Signatory",
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // Terms & Conditions - Only on last page
              if (pageNum == totalPages && termsAndConditions.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "TERMS & CONDITIONS",
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.only(left: 8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            left: pw.BorderSide(
                              color: pdfHeaderColor,
                              width: 2,
                            ),
                          ),
                        ),
                        child: pw.Text(
                          termsAndConditions,
                          style: pw.TextStyle(fontSize: 8, color: pdfTextColor),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              if (pageNum == totalPages)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 20, top: 10),
                  child: pw.Center(
                    child: pw.Text(
                      "This is a computer-generated quotation.",
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // PDF Helpers
  pw.Widget _pdfIconText(String text, PdfColor color) {
    return pw.Text(text, style: pw.TextStyle(color: color, fontSize: 9));
  }

  pw.Widget _pdfMetaRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
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
            fontSize: isGrand ? 11 : 9,
            fontWeight: isGrand ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          "${isNegative ? '-' : ''}$sym${value.toStringAsFixed(2)}",
          style: pw.TextStyle(
            fontSize: isGrand ? 11 : 9,
            fontWeight: isGrand ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isGrand ? grandColor : color,
          ),
        ),
      ],
    );
  }

  Future<void> _printQuote() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      final bytes = await _generateNativePdf();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Quote_$finalQuoteId',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Print failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _shareQuote() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      final bytes = await _generateNativePdf();
      final tempDir = await getTemporaryDirectory();
      final file = File("${tempDir.path}/Quote_$finalQuoteId.pdf");
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: "Here is the quotation from $businessName");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Share failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Quotation Preview",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Preview Area
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        minScale: 0.1,
                        maxScale: 4.0,
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(20),
                            child: Row(children: _buildAllPages()),
                          ),
                        ),
                      ),
                      if (_getTotalPages() > 1)
                        Positioned(
                          right: 20,
                          top: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.swipe_left,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Swipe to view ${_getTotalPages()} pages",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Action Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isActionLoading ? null : _shareQuote,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text("Share PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isActionLoading ? null : _printQuote,
                          icon: const Icon(Icons.print_rounded),
                          label: const Text("Print"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFF0F172A)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  // SCREEN WIDGETS
  Widget _buildScreenWatermark() {
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

  Widget _buildScreenHeader() {
    Color txtCol = headerColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    return Container(
      width: double.infinity,
      height: 130,
      color: headerColor,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_logoPath != null && File(_logoPath!).existsSync())
            Container(
              margin: const EdgeInsets.only(right: 15),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: FileImage(File(_logoPath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: alignStr == 'center'
                  ? CrossAxisAlignment.center
                  : (alignStr == 'right'
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start),
              children: [
                Text(
                  businessName,
                  style: GoogleFonts.inter(
                    color: txtCol,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (slogan.isNotEmpty)
                  Text(
                    slogan,
                    style: GoogleFonts.inter(
                      color: txtCol.withOpacity(0.8),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const Spacer(),
                if (address.isNotEmpty)
                  Text(
                    address,
                    style: GoogleFonts.inter(color: txtCol, fontSize: 9),
                  ),
                if (contact.isNotEmpty)
                  Text(
                    contact,
                    style: GoogleFonts.inter(color: txtCol, fontSize: 9),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenMeta({int pageNum = 1, int? totalPages}) {
    final items = quoteData['items'] as List<dynamic>? ?? [];
    final int pages = totalPages ?? _getTotalPages();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "QUOTATION FOR",
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              quoteData['customerName'] ?? 'Valued Client',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if ((quoteData['customerPhone'] ?? '').isNotEmpty)
              Text(
                quoteData['customerPhone'],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: textColor.withOpacity(0.7),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showLabel)
              Text(
                "QUOTATION",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: headerColor.withOpacity(0.3),
                ),
              ),
            _screenMetaRow("Quote No:", finalQuoteId),
            _screenMetaRow("Date:", quoteData['date'] ?? ""),
            if (validUntilDate.isNotEmpty)
              _screenMetaRow(
                "Valid Until:",
                validUntilDate,
                color: Colors.redAccent,
              ),
            // Page indicator for multi-page quotations
            if (pages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    border: Border.all(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Page $pageNum of $pages",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _screenMetaRow(String label, String value, {Color? color}) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
        const SizedBox(width: 5),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color ?? textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenTableHeaders() {
    Color txtCol = headerColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    return Container(
      color: headerColor,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              "S.No",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: txtCol,
              ),
            ),
          ),
          if (_hasPartNo)
            Expanded(
              flex: 2,
              child: Text(
                "SKU",
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: txtCol,
                ),
              ),
            ),
          Expanded(
            flex: 4,
            child: Text(
              "DESCRIPTION",
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: txtCol,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "QTY",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: txtCol,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "PRICE",
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: txtCol,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "TOTAL",
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: txtCol,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTableRows({int startIndex = 0, int? endIndex}) {
    List items = (quoteData['items'] as List?) ?? [];
    final int end = endIndex ?? items.length;

    return Column(
      children: List.generate(ITEMS_PER_PAGE, (index) {
        final int itemIndex = startIndex + index;
        if (itemIndex < end && itemIndex < items.length) {
          final item = items[itemIndex];
          double qty = _parseVal(item['qty']);
          double price = _parseVal(item['price']);
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "${itemIndex + 1}.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 10, color: textColor),
                  ),
                ),
                if (_hasPartNo)
                  Expanded(
                    flex: 2,
                    child: Text(
                      item['partNo']?.toString() ?? '',
                      style: GoogleFonts.inter(fontSize: 10, color: textColor),
                    ),
                  ),
                Expanded(
                  flex: 4,
                  child: Text(
                    item['name']?.toString() ?? '',
                    style: GoogleFonts.inter(fontSize: 10, color: textColor),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    qty.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 10, color: textColor),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    price.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(fontSize: 10, color: textColor),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    (qty * price).toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          height: 24,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
        );
      }),
    );
  }

  Widget _buildScreenTotals() {
    final totals = _calculateTotals();
    Color safeGrandColor = headerColor.computeLuminance() > 0.5
        ? Colors.black
        : headerColor;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        color: Colors.grey.shade50,
        child: Column(
          children: [
            _screenTotalRow("Subtotal", totals['sub']!),
            if (totals['tax']! > 0) _screenTotalRow("Tax", totals['tax']!),
            if (totals['discount']! > 0)
              _screenTotalRow(
                "Discount",
                totals['discount']!,
                isNegative: true,
              ),
            const Divider(height: 8),
            _screenTotalRow(
              "Total",
              totals['grand']!,
              isGrand: true,
              grandColor: safeGrandColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenTotalRow(
    String label,
    double val, {
    bool isGrand = false,
    bool isNegative = false,
    Color? grandColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isGrand ? 11 : 10,
            fontWeight: isGrand ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
        Text(
          "${isNegative ? '-' : ''}$currencySymbol${val.toStringAsFixed(2)}",
          style: GoogleFonts.inter(
            fontSize: isGrand ? 11 : 10,
            fontWeight: isGrand ? FontWeight.bold : FontWeight.normal,
            color: isGrand ? grandColor : textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenFooter() {
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
