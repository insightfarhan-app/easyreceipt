import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditTemplatePage extends StatefulWidget {
  const EditTemplatePage({super.key, required this.data});
  final Map data;

  @override
  State<EditTemplatePage> createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _paymentBankController = TextEditingController();
  final TextEditingController _paymentAccountController =
      TextEditingController();
  final TextEditingController _adminController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color _primaryColor = const Color(0xFF0F1C2E);
  final Color _accentColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _shadowColor = Colors.black12;

  @override
  void initState() {
    super.initState();
    _loadTemplate();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    _companyController.text = prefs.getString('company_name') ?? '';
    _sloganController.text = prefs.getString('slogan') ?? '';
    _paymentBankController.text = prefs.getString('payment_bank') ?? '';
    _paymentAccountController.text = prefs.getString('payment_account') ?? '';
    _adminController.text = prefs.getString('admin_name') ?? '';
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', _companyController.text.trim());
    await prefs.setString('slogan', _sloganController.text.trim());
    await prefs.setString('payment_bank', _paymentBankController.text.trim());
    await prefs.setString(
      'payment_account',
      _paymentAccountController.text.trim(),
    );
    await prefs.setString('admin_name', _adminController.text.trim());
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          filled: true,
          fillColor: _cardColor,
          labelStyle: TextStyle(color: _primaryColor.withOpacity(0.7)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _accentColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _shadowColor, width: 1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        title: const Text(
          'Edit Template',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Your Template",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Customize your company details, payment information, and admin settings.",
                style: TextStyle(
                  fontSize: 14,
                  color: _primaryColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _companyController,
                      label: "Company Name",
                      maxLength: 12,
                    ),
                    _buildTextField(
                      controller: _sloganController,
                      label: "Slogan",
                      maxLength: 32,
                    ),
                    _buildTextField(
                      controller: _paymentBankController,
                      label: "Bank Name",
                    ),
                    _buildTextField(
                      controller: _paymentAccountController,
                      label: "Bank Account",
                    ),
                    _buildTextField(
                      controller: _adminController,
                      label: "Administrator Name",
                      maxLength: 12,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveTemplate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: _accentColor,
                        elevation: 8,
                        shadowColor: _shadowColor,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Save",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
