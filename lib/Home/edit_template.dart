import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';

class EditTemplatePage extends StatefulWidget {
  const EditTemplatePage({super.key, required this.data});
  final Map data;

  @override
  State<EditTemplatePage> createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage>
    with SingleTickerProviderStateMixin {
  final _companyController = TextEditingController();
  final _sloganController = TextEditingController();
  final _adminController = TextEditingController();
  final _invoiceStartController = TextEditingController();
  final _policyController = TextEditingController();
  final _watermarkController = TextEditingController();

  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _descController = TextEditingController();

  int _headerColor = 0xFFFFFFFF;
  int _bgColor = 0xFFFFFFFF;
  int _textColor = 0xFF000000;
  String _alignment = 'left';
  bool _showInvoiceLabel = true;
  String _currency = 'USD';
  String _watermarkStyle = 'diagonal';

  String? _logoPath;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _controller;
  late Animation<double> _fade;

  final Color _primaryColor = const Color(0xFF2563EB);

  final List<int> _colorPalette = [
    0xFF000000,
    0xFFFFFFFF,
    0xFF2563EB,
    0xFFE53935,
    0xFF43A047,
    0xFFFB8C00,
    0xFF8E24AA,
    0xFF0F1C2E,
    0xFF607D8B,
    0xFFD1D5DB, // Light Grey
    0xFFBFDBFE, // Light Blue
    0xFFFBCFE8, // Light Pink
    0xFFD97706, // Light Brown/Amber
  ];

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'United States Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': 'Rs'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': 'INR'},
    {'code': 'AED', 'name': 'United Arab Emirates Dirham', 'symbol': 'AED'},
    {'code': 'AFN', 'name': 'Afghan Afghani', 'symbol': 'AFN'},
    {'code': 'ALL', 'name': 'Albanian Lek', 'symbol': 'ALL'},
    {'code': 'AMD', 'name': 'Armenian Dram', 'symbol': 'AMD'},
    {'code': 'ANG', 'name': 'Netherlands Antillean Guilder', 'symbol': 'ANG'},
    {'code': 'AOA', 'name': 'Angolan Kwanza', 'symbol': 'AOA'},
    {'code': 'ARS', 'name': 'Argentine Peso', 'symbol': 'ARS'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'AUD'},
    {'code': 'AWG', 'name': 'Aruban Florin', 'symbol': 'AWG'},
    {'code': 'AZN', 'name': 'Azerbaijani Manat', 'symbol': 'AZN'},
    {
      'code': 'BAM',
      'name': 'Bosnia-Herzegovina Convertible Mark',
      'symbol': 'BAM',
    },
    {'code': 'BBD', 'name': 'Barbadian Dollar', 'symbol': 'BBD'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka', 'symbol': 'BDT'},
    {'code': 'BGN', 'name': 'Bulgarian Lev', 'symbol': 'BGN'},
    {'code': 'BHD', 'name': 'Bahraini Dinar', 'symbol': 'BHD'},
    {'code': 'BIF', 'name': 'Burundian Franc', 'symbol': 'BIF'},
    {'code': 'BMD', 'name': 'Bermudian Dollar', 'symbol': 'BMD'},
    {'code': 'BND', 'name': 'Brunei Dollar', 'symbol': 'BND'},
    {'code': 'BOB', 'name': 'Bolivian Boliviano', 'symbol': 'BOB'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'BRL'},
    {'code': 'BSD', 'name': 'Bahamian Dollar', 'symbol': 'BSD'},
    {'code': 'BTN', 'name': 'Bhutanese Ngultrum', 'symbol': 'BTN'},
    {'code': 'BWP', 'name': 'Botswana Pula', 'symbol': 'BWP'},
    {'code': 'BYN', 'name': 'Belarusian Ruble', 'symbol': 'BYN'},
    {'code': 'BZD', 'name': 'Belize Dollar', 'symbol': 'BZD'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'CAD'},
    {'code': 'CDF', 'name': 'Congolese Franc', 'symbol': 'CDF'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'CLP', 'name': 'Chilean Peso', 'symbol': 'CLP'},
    {'code': 'COP', 'name': 'Colombian Peso', 'symbol': 'COP'},
    {'code': 'CRC', 'name': 'Costa Rican Colón', 'symbol': 'CRC'},
    {'code': 'CUP', 'name': 'Cuban Peso', 'symbol': 'CUP'},
    {'code': 'CVE', 'name': 'Cape Verdean Escudo', 'symbol': 'CVE'},
    {'code': 'CZK', 'name': 'Czech Koruna', 'symbol': 'CZK'},
    {'code': 'DJF', 'name': 'Djiboutian Franc', 'symbol': 'DJF'},
    {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'DKK'},
    {'code': 'DOP', 'name': 'Dominican Peso', 'symbol': 'DOP'},
    {'code': 'DZD', 'name': 'Algerian Dinar', 'symbol': 'DZD'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': 'EGP'},
    {'code': 'ERN', 'name': 'Eritrean Nakfa', 'symbol': 'ERN'},
    {'code': 'ETB', 'name': 'Ethiopian Birr', 'symbol': 'ETB'},
    {'code': 'FJD', 'name': 'Fijian Dollar', 'symbol': 'FJD'},
    {'code': 'FKP', 'name': 'Falkland Islands Pound', 'symbol': 'FKP'},
    {'code': 'GEL', 'name': 'Georgian Lari', 'symbol': 'GEL'},
    {'code': 'GHS', 'name': 'Ghanaian Cedi', 'symbol': 'GHS'},
    {'code': 'GIP', 'name': 'Gibraltar Pound', 'symbol': 'GIP'},
    {'code': 'GMD', 'name': 'Gambian Dalasi', 'symbol': 'GMD'},
    {'code': 'GNF', 'name': 'Guinean Franc', 'symbol': 'GNF'},
    {'code': 'GTQ', 'name': 'Guatemalan Quetzal', 'symbol': 'GTQ'},
    {'code': 'GYD', 'name': 'Guyanese Dollar', 'symbol': 'GYD'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': 'HKD'},
    {'code': 'HNL', 'name': 'Honduran Lempira', 'symbol': 'HNL'},
    {'code': 'HRK', 'name': 'Croatian Kuna', 'symbol': 'HRK'},
    {'code': 'HTG', 'name': 'Haitian Gourde', 'symbol': 'HTG'},
    {'code': 'HUF', 'name': 'Hungarian Forint', 'symbol': 'HUF'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'IDR'},
    {'code': 'ILS', 'name': 'Israeli New Shekel', 'symbol': 'ILS'},
    {'code': 'IQD', 'name': 'Iraqi Dinar', 'symbol': 'IQD'},
    {'code': 'IRR', 'name': 'Iranian Rial', 'symbol': 'IRR'},
    {'code': 'ISK', 'name': 'Icelandic Króna', 'symbol': 'ISK'},
    {'code': 'JMD', 'name': 'Jamaican Dollar', 'symbol': 'JMD'},
    {'code': 'JOD', 'name': 'Jordanian Dinar', 'symbol': 'JOD'},
    {'code': 'KES', 'name': 'Kenyan Shilling', 'symbol': 'KES'},
    {'code': 'KGS', 'name': 'Kyrgyzstani Som', 'symbol': 'KGS'},
    {'code': 'KHR', 'name': 'Cambodian Riel', 'symbol': 'KHR'},
    {'code': 'KMF', 'name': 'Comorian Franc', 'symbol': 'KMF'},
    {'code': 'KPW', 'name': 'North Korean Won', 'symbol': 'KPW'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': 'KRW'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar', 'symbol': 'KWD'},
    {'code': 'KYD', 'name': 'Cayman Islands Dollar', 'symbol': 'KYD'},
    {'code': 'KZT', 'name': 'Kazakhstani Tenge', 'symbol': 'KZT'},
    {'code': 'LAK', 'name': 'Lao Kip', 'symbol': 'LAK'},
    {'code': 'LBP', 'name': 'Lebanese Pound', 'symbol': 'LBP'},
    {'code': 'LKR', 'name': 'Sri Lankan Rupee', 'symbol': 'LKR'},
    {'code': 'LRD', 'name': 'Liberian Dollar', 'symbol': 'LRD'},
    {'code': 'LSL', 'name': 'Lesotho Loti', 'symbol': 'LSL'},
    {'code': 'LYD', 'name': 'Libyan Dinar', 'symbol': 'LYD'},
    {'code': 'MAD', 'name': 'Moroccan Dirham', 'symbol': 'MAD'},
    {'code': 'MDL', 'name': 'Moldovan Leu', 'symbol': 'MDL'},
    {'code': 'MGA', 'name': 'Malagasy Ariary', 'symbol': 'MGA'},
    {'code': 'MKD', 'name': 'Macedonian Denar', 'symbol': 'MKD'},
    {'code': 'MMK', 'name': 'Burmese Kyat', 'symbol': 'MMK'},
    {'code': 'MNT', 'name': 'Mongolian Tögrög', 'symbol': 'MNT'},
    {'code': 'MOP', 'name': 'Macanese Pataca', 'symbol': 'MOP'},
    {'code': 'MRU', 'name': 'Mauritanian Ouguiya', 'symbol': 'MRU'},
    {'code': 'MUR', 'name': 'Mauritian Rupee', 'symbol': 'MUR'},
    {'code': 'MVR', 'name': 'Maldivian Rufiyaa', 'symbol': 'MVR'},
    {'code': 'MWK', 'name': 'Malawian Kwacha', 'symbol': 'MWK'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': 'MXN'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'MYR'},
    {'code': 'MZN', 'name': 'Mozambican Metical', 'symbol': 'MZN'},
    {'code': 'NAD', 'name': 'Namibian Dollar', 'symbol': 'NAD'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': 'NGN'},
    {'code': 'NIO', 'name': 'Nicaraguan Córdoba', 'symbol': 'NIO'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'NOK'},
    {'code': 'NPR', 'name': 'Nepalese Rupee', 'symbol': 'NPR'},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'symbol': 'NZD'},
    {'code': 'OMR', 'name': 'Omani Rial', 'symbol': 'OMR'},
    {'code': 'PAB', 'name': 'Panamanian Balboa', 'symbol': 'PAB'},
    {'code': 'PEN', 'name': 'Peruvian Sol', 'symbol': 'PEN'},
    {'code': 'PGK', 'name': 'Papua New Guinean Kina', 'symbol': 'PGK'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': 'PHP'},
    {'code': 'PLN', 'name': 'Polish Złoty', 'symbol': 'PLN'},
    {'code': 'PYG', 'name': 'Paraguayan Guaraní', 'symbol': 'PYG'},
    {'code': 'QAR', 'name': 'Qatari Riyal', 'symbol': 'QAR'},
    {'code': 'RON', 'name': 'Romanian Leu', 'symbol': 'RON'},
    {'code': 'RSD', 'name': 'Serbian Dinar', 'symbol': 'RSD'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': 'RUB'},
    {'code': 'RWF', 'name': 'Rwandan Franc', 'symbol': 'RWF'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'SAR'},
    {'code': 'SBD', 'name': 'Solomon Islands Dollar', 'symbol': 'SBD'},
    {'code': 'SCR', 'name': 'Seychellois Rupee', 'symbol': 'SCR'},
    {'code': 'SDG', 'name': 'Sudanese Pound', 'symbol': 'SDG'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'SEK'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'SGD'},
    {'code': 'SHP', 'name': 'Saint Helena Pound', 'symbol': 'SHP'},
    {'code': 'SLL', 'name': 'Sierra Leonean Leone', 'symbol': 'SLL'},
    {'code': 'SOS', 'name': 'Somali Shilling', 'symbol': 'SOS'},
    {'code': 'SRD', 'name': 'Surinamese Dollar', 'symbol': 'SRD'},
    {'code': 'SSP', 'name': 'South Sudanese Pound', 'symbol': 'SSP'},
    {'code': 'STN', 'name': 'São Tomé and Príncipe Dobra', 'symbol': 'STN'},
    {'code': 'SYP', 'name': 'Syrian Pound', 'symbol': 'SYP'},
    {'code': 'SZL', 'name': 'Swazi Lilangeni', 'symbol': 'SZL'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': 'THB'},
    {'code': 'TJS', 'name': 'Tajikistani Somoni', 'symbol': 'TJS'},
    {'code': 'TMT', 'name': 'Turkmenistani Manat', 'symbol': 'TMT'},
    {'code': 'TND', 'name': 'Tunisian Dinar', 'symbol': 'TND'},
    {'code': 'TOP', 'name': 'Tongan Paʻanga', 'symbol': 'TOP'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': 'TRY'},
    {'code': 'TTD', 'name': 'Trinidad and Tobago Dollar', 'symbol': 'TTD'},
    {'code': 'TWD', 'name': 'New Taiwan Dollar', 'symbol': 'TWD'},
    {'code': 'TZS', 'name': 'Tanzanian Shilling', 'symbol': 'TZS'},
    {'code': 'UAH', 'name': 'Ukrainian Hryvnia', 'symbol': 'UAH'},
    {'code': 'UGX', 'name': 'Ugandan Shilling', 'symbol': 'UGX'},
    {'code': 'UYU', 'name': 'Uruguayan Peso', 'symbol': 'UYU'},
    {'code': 'UZS', 'name': 'Uzbekistani Soʻm', 'symbol': 'UZS'},
    {'code': 'VES', 'name': 'Venezuelan Bolívar', 'symbol': 'VES'},
    {'code': 'VND', 'name': 'Vietnamese Đồng', 'symbol': 'VND'},
    {'code': 'VUV', 'name': 'Vanuatu Vatu', 'symbol': 'VUV'},
    {'code': 'WST', 'name': 'Samoan Tala', 'symbol': 'WST'},
    {'code': 'XAF', 'name': 'Central African CFA Franc', 'symbol': 'XAF'},
    {'code': 'XCD', 'name': 'East Caribbean Dollar', 'symbol': 'XCD'},
    {'code': 'XOF', 'name': 'West African CFA Franc', 'symbol': 'XOF'},
    {'code': 'XPF', 'name': 'CFP Franc', 'symbol': 'XPF'},
    {'code': 'YER', 'name': 'Yemeni Rial', 'symbol': 'YER'},
    {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'ZAR'},
    {'code': 'ZMW', 'name': 'Zambian Kwacha', 'symbol': 'ZMW'},
    {'code': 'ZWL', 'name': 'Zimbabwean Dollar', 'symbol': 'ZWL'},
  ];

  @override
  void initState() {
    super.initState();
    _currencies.sort((a, b) => a['name']!.compareTo(b['name']!));
    _loadTemplate();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _sloganController.dispose();
    _adminController.dispose();
    _invoiceStartController.dispose();
    _policyController.dispose();
    _watermarkController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        setState(() => _logoPath = image.path);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'company_logo_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImage = await File(
          image.path,
        ).copy('${appDir.path}/$fileName');
        setState(() => _logoPath = savedImage.path);
      }
    }
  }

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    _companyController.text = prefs.getString('company_name') ?? 'Company Name';
    _sloganController.text = prefs.getString('slogan') ?? 'Best in City';
    _adminController.text = prefs.getString('admin_name') ?? 'Administrator';

    _addressController.text = prefs.getString('company_address') ?? '';
    _contactController.text = prefs.getString('company_contact') ?? '';
    _descController.text = prefs.getString('company_desc') ?? '';

    _invoiceStartController.text =
        prefs.getString('invoice_sequence') ?? '0000';
    _policyController.text = prefs.getString('invoice_policy') ?? '';
    _watermarkController.text = prefs.getString('watermark_text') ?? '';

    setState(() {
      _headerColor = prefs.getInt('header_color') ?? 0xFFFFFFFF;
      _bgColor = prefs.getInt('bg_color') ?? 0xFFFFFFFF;
      _textColor = prefs.getInt('text_color') ?? 0xFF000000;
      _alignment = prefs.getString('company_align') ?? 'left';
      _showInvoiceLabel = prefs.getBool('show_invoice_label') ?? true;
      _logoPath = prefs.getString('company_logo');
      _currency = prefs.getString('currency_code') ?? 'USD';
      _watermarkStyle = prefs.getString('watermark_style') ?? 'diagonal';
    });
  }

  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', _companyController.text.trim());
    await prefs.setString('slogan', _sloganController.text.trim());
    await prefs.setString('admin_name', _adminController.text.trim());

    await prefs.setString('company_address', _addressController.text.trim());
    await prefs.setString('company_contact', _contactController.text.trim());
    await prefs.setString('company_desc', _descController.text.trim());

    String seq = _invoiceStartController.text.trim();
    if (seq.isEmpty) seq = "0000";
    await prefs.setString('invoice_sequence', seq);

    await prefs.setString('invoice_policy', _policyController.text.trim());
    await prefs.setString('watermark_text', _watermarkController.text.trim());
    await prefs.setString('watermark_style', _watermarkStyle);

    await prefs.setInt('header_color', _headerColor);
    await prefs.setInt('bg_color', _bgColor);
    await prefs.setInt('text_color', _textColor);
    await prefs.setString('company_align', _alignment);
    await prefs.setBool('show_invoice_label', _showInvoiceLabel);

    await prefs.setString('currency_code', _currency);
    String symbol = _currencies.firstWhere(
      (c) => c['code'] == _currency,
      orElse: () => {'symbol': '\$'},
    )['symbol']!;
    await prefs.setString('currency_symbol', symbol);

    if (_logoPath != null) {
      await prefs.setString('company_logo', _logoPath!);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  ImageProvider? _getLogoImage() {
    if (_logoPath == null) return null;
    if (kIsWeb) {
      return NetworkImage(_logoPath!);
    } else {
      return FileImage(File(_logoPath!));
    }
  }

  void _showCurrencyPicker() {
    final colors = AppColors(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = "";
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final filtered = _currencies.where((c) {
                  final q = searchQuery.toLowerCase();
                  return c['name']!.toLowerCase().contains(q) ||
                      c['code']!.toLowerCase().contains(q);
                }).toList();

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            width: 40,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          TextField(
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: "Search country or currency...",
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: colors.inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                searchQuery = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                "No currency found",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                color: Colors.grey.shade200,
                                height: 1,
                              ),
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                final isSelected = item['code'] == _currency;

                                return ListTile(
                                  onTap: () {
                                    setState(() => _currency = item['code']!);
                                    Navigator.pop(context);
                                  },
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _primaryColor.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isSelected
                                          ? Border.all(color: _primaryColor)
                                          : null,
                                    ),
                                    child: Text(
                                      item['symbol']!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? _primaryColor
                                            : Colors.orangeAccent,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item['name']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? _primaryColor
                                          : colors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item['code']!,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: _primaryColor,
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _currencySelectorWidget(AppColors colors) {
    final selectedItem = _currencies.firstWhere(
      (c) => c['code'] == _currency,
      orElse: () => _currencies.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: _showCurrencyPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedItem['symbol']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Currency",
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${selectedItem['code']} - ${selectedItem['name']}",
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: colors.icon),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whiteCard(AppColors colors, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _field(
    AppColors colors,
    String label,
    TextEditingController controller, {
    int? max,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLength: max,
        maxLines: lines,
        keyboardType: label.contains("Invoice #")
            ? TextInputType.number
            : TextInputType.text,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          labelStyle: TextStyle(color: colors.textSecondary),
          filled: true,
          fillColor: colors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _colorPicker(
    AppColors colors,
    String title,
    int selected,
    Function(int) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12, // Added runSpacing for multiple lines
          children: _colorPalette.map((c) {
            final selectedColor = c == selected;
            return GestureDetector(
              onTap: () => onTap(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor ? _primaryColor : colors.border,
                    width: selectedColor ? 3 : 1,
                  ),
                  boxShadow: [
                    if (selectedColor)
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: c == 0xFFFFFFFF
                    ? Icon(Icons.format_paint, size: 14, color: colors.icon)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          "Edit Template",
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _whiteCard(
                  colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Brand Identity",
                        style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _pickLogo,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: colors.surface,
                            backgroundImage: _getLogoImage(),
                            child: _logoPath == null
                                ? Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: colors.icon,
                                    size: 32,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Tap to upload logo",
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _field(
                        colors,
                        "Company Name",
                        _companyController,
                        max: 30,
                      ),
                      _field(colors, "Slogan", _sloganController, max: 40),

                      _field(colors, "Address", _addressController, max: 60),
                      _field(
                        colors,
                        "Contact (Phone/Email)",
                        _contactController,
                        max: 50,
                      ),
                      _field(
                        colors,
                        "Business Desc (We deal in...)",
                        _descController,
                        max: 100,
                        lines: 2,
                      ),

                      _currencySelectorWidget(colors),
                      _field(
                        colors,
                        "Administrator Name",
                        _adminController,
                        max: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _whiteCard(
                  colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Invoice Details & Extras",
                        style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Next Invoice Number:",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _field(
                        colors,
                        "Start Invoice # (e.g. 0000)",
                        _invoiceStartController,
                        max: 10,
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Show Invoice Label",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Switch(
                            value: _showInvoiceLabel,
                            onChanged: (val) {
                              setState(() => _showInvoiceLabel = val);
                            },
                            activeThumbColor: _primaryColor,
                            activeTrackColor: _primaryColor.withOpacity(0.4),
                            inactiveThumbColor: colors.icon,
                            inactiveTrackColor: colors.border,
                            trackOutlineColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return _primaryColor;
                              }
                              return colors.textSecondary;
                            }),
                          ),
                        ],
                      ),

                      const Divider(height: 30),
                      Text(
                        "Watermark Settings",
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _field(
                        colors,
                        "Watermark Text (max 45 chars, 15 per line)",
                        _watermarkController,
                        max: 45,
                      ),

                      Row(
                        children: [
                          Text(
                            "Alignment: ",
                            style: TextStyle(color: colors.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text("Diagonal"),
                            selected: _watermarkStyle == 'diagonal',
                            onSelected: (v) =>
                                setState(() => _watermarkStyle = 'diagonal'),
                            selectedColor: _primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _watermarkStyle == 'diagonal'
                                  ? _primaryColor
                                  : colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text("Straight"),
                            selected: _watermarkStyle == 'horizontal',
                            onSelected: (v) =>
                                setState(() => _watermarkStyle = 'horizontal'),
                            selectedColor: _primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _watermarkStyle == 'horizontal'
                                  ? _primaryColor
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 30),
                      Text(
                        "Footer Notes",
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _field(
                        colors,
                        "Terms & Conditions / Policy",
                        _policyController,
                        max: 245,
                        lines: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _whiteCard(
                  colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _colorPicker(
                        colors,
                        "Header Background Color",
                        _headerColor,
                        (v) => setState(() => _headerColor = v),
                      ),

                      _colorPicker(
                        colors,
                        "Text Color",
                        _textColor,
                        (v) => setState(() => _textColor = v),
                      ),

                      _colorPicker(
                        colors,
                        "Invoice Background Color",
                        _bgColor,
                        (v) => setState(() => _bgColor = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTemplate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.textPrimary,
                      foregroundColor: colors.card,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: colors.textPrimary.withOpacity(0.4),
                    ),
                    child: Text(
                      "Save Template",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
