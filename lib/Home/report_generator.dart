import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ReportGenerator {
  // 🟢 Professional Color Palette
  static const PdfColor _primaryColor = PdfColors.blue800;
  static const PdfColor _accentColor = PdfColors.blueGrey50;
  static const PdfColor _textColor = PdfColors.blueGrey900;
  static const PdfColor _subTextColor = PdfColors.blueGrey600;

  /// 🟢 Generates the PDF bytes
  static Future<Uint8List> generateBytes({
    required List<Map<String, dynamic>> invoices,
    required String rangeName,
    required double totalSales,
    required double cashSales,
    required double creditSales,
    required double totalTax,
  }) async {
    final pdf = pw.Document();

    // Load Fonts (Inter is excellent for professional reports)
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontSemiBold = await PdfGoogleFonts.interMedium();

    // Load Company Details
    final prefs = await SharedPreferences.getInstance();
    final companyName = prefs.getString("company_name") ?? "My Company";
    final currency = prefs.getString("currency_symbol") ?? "\$";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 40),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),

        // 🟢 PROFESSIONAL HEADER
        header: (context) => _buildHeader(companyName, rangeName, context),

        // 🟢 PROFESSIONAL FOOTER
        footer: (context) => _buildFooter(context),

        build: (context) => [
          // 1. Summary Section (Top of report for quick view)
          _buildTopSummary(totalSales, totalTax, invoices.length, currency),

          pw.SizedBox(height: 25),

          pw.Text(
            "TRANSACTION DETAILS",
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 5),

          // 2. Data Table
          _buildInvoiceTable(invoices, currency),

          pw.SizedBox(height: 30),

          // 3. 🟢 REDESIGNED TOTALS SECTION
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              _buildBottomSummary(
                cashSales,
                creditSales,
                totalTax,
                totalSales,
                currency,
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// 🟢 Direct Print Function
  static Future<void> printReport({
    required List<Map<String, dynamic>> invoices,
    required String rangeName,
    required double totalSales,
    required double cashSales,
    required double creditSales,
    required double totalTax,
  }) async {
    final bytes = await generateBytes(
      invoices: invoices,
      rangeName: rangeName,
      totalSales: totalSales,
      cashSales: cashSales,
      creditSales: creditSales,
      totalTax: totalTax,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Sales_Report',
    );
  }

  // --- WIDGET BUILDERS ---

  static pw.Widget _buildHeader(
    String companyName,
    String range,
    pw.Context context,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Info (Left)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Sales Report",
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: _subTextColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Report Meta Data (Right)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "GENERATED ON",
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10, color: _textColor),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "PERIOD",
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    range,
                    style: const pw.TextStyle(fontSize: 10, color: _textColor),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
        ],
      ),
    );
  }

  static pw.Widget _buildTopSummary(
    double grandTotal,
    double tax,
    int count,
    String currency,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: _accentColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.blueGrey100),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildTopSummaryItem("Total Invoices", "$count"),
          _buildTopSummaryItem(
            "Total Tax Collected",
            "$currency ${tax.toStringAsFixed(2)}",
          ),
          _buildTopSummaryItem(
            "Net Revenue",
            "$currency ${grandTotal.toStringAsFixed(2)}",
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTopSummaryItem(
    String label,
    String value, {
    bool isPrimary = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: isPrimary ? _primaryColor : _textColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceTable(
    List<Map<String, dynamic>> invoices,
    String currency,
  ) {
    final headers = [
      'INVOICE ID',
      'DATE',
      'CUSTOMER',
      'TYPE',
      'STATUS',
      'AMOUNT',
    ];

    final data = invoices.map((inv) {
      final dateRaw = inv['invoiceDate'] ?? inv['savedAt'] ?? "";
      String dateStr = "-";
      try {
        final d = DateTime.parse(dateRaw);
        dateStr = DateFormat('MMM dd, yyyy').format(d);
      } catch (_) {}

      final total = double.tryParse(inv['grandTotal'].toString()) ?? 0.0;

      return [
        inv['invoiceId']?.toString() ?? "-",
        dateStr,
        inv['customerName']?.toString() ?? "Unknown",
        inv['invoiceType']?.toString() ?? "Credit",
        inv['status']?.toString() ?? "-",
        "$currency ${total.toStringAsFixed(2)}",
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
      ),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _textColor),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
      ),
      // Zebra Striping
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {5: pw.Alignment.centerRight},
      cellPadding: const pw.EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 10,
      ),
    );
  }

  // 🟢 NEW PROFESSIONAL SUMMARY BOX
  static pw.Widget _buildBottomSummary(
    double cash,
    double credit,
    double tax,
    double total,
    String currency,
  ) {
    return pw.Container(
      width: 260,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          // White Area for Details
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: PdfColors.white,
            child: pw.Column(
              children: [
                _buildSummaryRow("Cash Sales", cash, currency),
                pw.SizedBox(height: 6),
                _buildSummaryRow("Credit Sales", credit, currency),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Divider(color: PdfColors.grey200, thickness: 1),
                ),
                _buildSummaryRow("Total Tax", tax, currency),
              ],
            ),
          ),

          // Colored Footer for Grand Total
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            decoration: const pw.BoxDecoration(
              color: _primaryColor,
              borderRadius: pw.BorderRadius.vertical(
                bottom: pw.Radius.circular(4),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "GRAND TOTAL",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  "$currency ${total.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double value,
    String currency,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: _subTextColor),
        ),
        pw.Text(
          "$currency ${value.toStringAsFixed(2)}",
          style: pw.TextStyle(
            fontSize: 10,
            color: _textColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Powered by EasyInvoice",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            "Page ${context.pageNumber} of ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
