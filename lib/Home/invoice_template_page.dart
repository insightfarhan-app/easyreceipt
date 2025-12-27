import 'dart:ui';
import 'package:EasyInvoice/Home/edit_template.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceTemplatePage extends StatefulWidget {
  final Map<String, Object> invoiceData;
  const InvoiceTemplatePage({super.key, required this.invoiceData});

  @override
  State<InvoiceTemplatePage> createState() => _InvoiceTemplatePageState();
}

class _InvoiceTemplatePageState extends State<InvoiceTemplatePage> {
  String businessName = "Company Name";
  String slogan = "Best in City";
  String bankName = "Francisco Andrade";
  String bankAccount = "1234567890";
  String adminName = "Administrator Name";
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    businessName = prefs.getString("company_name") ?? "Company Name";
    slogan = prefs.getString("slogan") ?? "Your Business Partner";
    bankName = prefs.getString("payment_bank") ?? "Francisco Andrade";
    bankAccount = prefs.getString("payment_account") ?? "1234567890";
    adminName = prefs.getString("admin_name") ?? "Drew Feig";
    setState(() => _loaded = true);
  }

  Future<void> _openEditPage() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditTemplatePage(data: {})),
    );
    if (updated == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Invoice Preview",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _openEditPage,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: _buildTemplateContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateContent() {
    double label = 13;
    double text = 12;
    double heading = 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: const Color.fromARGB(255, 94, 93, 93),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ],
          ),
        ),

        const SizedBox(height: 12),
        Divider(thickness: 1.2),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "INVOICE TO:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: label,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Custumer Name",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: heading,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Phone No: +123-456-7890",
                  style: TextStyle(fontSize: text),
                ),
                Text(
                  "Address: city, country",
                  style: TextStyle(fontSize: text),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "INVOICE INFO",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: label,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 8),
                Text("ID: 1234567890", style: TextStyle(fontSize: text)),
                Text("Date: 12/07/2023", style: TextStyle(fontSize: text)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromARGB(255, 6, 6, 6)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: const [
                    Expanded(
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
                      width: 60,
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
                      width: 60,
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

              _row("Storybook", 2, 120),
              _row("Magazine", 4, 100),
              _row("Notebooks", 2, 120),
              _row("Comics", 3, 130),
              _row("Novel", 2, 120),

              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.black),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text("Sub-total : 1735"),
                      Text("Tax : 55"),
                      Text("Discount : 10%"),
                      SizedBox(height: 5),
                      Text(
                        "Total : 1680",
                        style: TextStyle(
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

        const SizedBox(height: 25),
        Text(
          "Payment Method:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: label),
        ),
        const SizedBox(height: 4),
        Text("Bank Name: $bankName", style: TextStyle(fontSize: text)),
        Text("Bank Account: $bankAccount", style: TextStyle(fontSize: text)),
        const SizedBox(height: 20),

        Center(
          child: Text(
            "Thank you for purchase!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerRight,
          child: Column(
            children: [
              Text(adminName),
              const SizedBox(height: 0),
              const Text("Administrator", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String name, int qty, int price) {
    int total = qty * price;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(name, style: const TextStyle(fontSize: 12)),
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
            width: 60,
            child: Text(
              "\$$price",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              "\$$total",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
