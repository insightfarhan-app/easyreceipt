import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

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
  ScreenshotController screenshotController = ScreenshotController();

  String businessName = "Company Name";
  String slogan = "Your Business Partner";
  String bankName = "Francisco Andrade";
  String bankAccount = "1234567890";
  String adminName = "Drew Feig";
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    invoiceData = Map<String, dynamic>.from(widget.data);
    _loadTemplateData();
  }

  Future<void> _loadTemplateData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      businessName = prefs.getString("company_name") ?? "Company Name";
      slogan = prefs.getString("slogan") ?? "Your Business Partner";
      bankName = prefs.getString("payment_bank") ?? "Francisco Andrade";
      bankAccount = prefs.getString("payment_account") ?? "1234567890";
      adminName = prefs.getString("admin_name") ?? "Drew Feig";
      _loaded = true;
    });
  }

  Future<void> _printInvoiceHD() async {
    try {
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 4.0,
      );
      if (imageBytes == null) return;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Printing failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareAsPdf() async {
    try {
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 3.0,
      );
      if (imageBytes == null) return;

      final pdf = pw.Document(compress: true);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
          ),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File(
        "${tempDir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: "Invoice PDF");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to generate PDF: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareAsImage() async {
    try {
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 3.0,
      );
      if (imageBytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_share.png');
      await file.writeAsBytes(imageBytes);

      Share.shareXFiles([XFile(file.path)], text: "Invoice from $businessName");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share as image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Share Invoice As",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white),
              title: const Text(
                "Share as Image",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareAsImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.white),
              title: const Text(
                "Share as PDF",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareAsPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Screenshot(
                      controller: screenshotController,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: _buildInvoiceContent(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showShareOptions,
                          icon: const Icon(Icons.share),
                          label: const Text("Share Invoice"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blueAccent.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _printInvoiceHD,
                          icon: const Icon(Icons.print),
                          label: const Text("Print Invoice"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceContent() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: const Color.fromARGB(255, 94, 93, 93)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          slogan,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Text(
                  "INVOICE",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "INVOICE TO:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      invoiceData['customerName'] ?? 'Customer Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    if ((invoiceData['customerPhone'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        "Phone No: ${invoiceData['customerPhone']}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if ((invoiceData['customerAddress'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        "Address: ${invoiceData['customerAddress']}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "INVOICE INFO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ID: ${invoiceData['invoiceId'] ?? 'INV-000001'}",
                    style: const TextStyle(fontSize: 9),
                  ),
                  Text(
                    "Date: ${invoiceData['invoiceDate'] ?? '01/01/2023'}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromARGB(255, 10, 10, 10)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            "PRODUCTS",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 45,
                        child: Text(
                          "QTY",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          "PRICE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          "TOTAL",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ...((invoiceData['items'] ?? []).map<Widget>((item) {
                  return _productRow(
                    item['name'] ?? 'Product',
                    item['qty'] ?? 0,
                    (item['price'] ?? 0.0).toDouble(),
                    (item['total'] ?? 0.0).toDouble(),
                  );
                }).toList()),

                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Sub-total : ${(invoiceData['subtotal'] ?? 0.0).toStringAsFixed(2)}",
                        ),
                        if ((invoiceData['tax'] ?? 0.0) > 0)
                          Text(
                            "Tax : ${(invoiceData['tax'] ?? 0.0).toStringAsFixed(2)}",
                          ),
                        if ((invoiceData['discount'] ?? 0.0) > 0)
                          Text(
                            "Discount : ${(invoiceData['discount'] ?? 0.0).toStringAsFixed(2)}",
                          ),
                        const SizedBox(height: 5),
                        Text(
                          "Total : ${(invoiceData['grandTotal'] ?? 0.0).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Text(
            "Payment Method:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 4),
          Text("Bank Name: $bankName", style: const TextStyle(fontSize: 12)),
          Text(
            "Bank Account: $bankAccount",
            style: const TextStyle(fontSize: 12),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              "Thank you for your purchase!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              children: [
                Text(adminName),
                const Text(
                  "Administrator",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productRow(String name, int qty, double price, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              "$qty",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              price.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              total.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
