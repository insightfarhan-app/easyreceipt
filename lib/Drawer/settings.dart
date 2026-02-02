import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:EasyInvoice/Provider/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- DESIGN CONSTANTS ---
  final Color _primaryColor = const Color(0xFF2563EB); // Royal Blue

  // --- LOGIC VARIABLES ---
  bool _appLock = false;
  bool _smartLock = false;
  bool _biometricsAvailable = false;
  final LocalAuthentication _auth = LocalAuthentication();

  // --- UPDATE VARIABLES ---
  bool _isCheckingUpdate = false;
  bool _updateAvailable = false;
  String _lastChecked = "Never";
  String _currentVersion = "Loading...";

  // Your App Link
  final String _playStoreUrl =
      "https://play.google.com/store/apps/details?id=com.easyinvoice.appxplora";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _checkHardware();
    await _loadSettings();
    await _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  Future<void> _checkHardware() async {
    bool isSupported = await _auth.isDeviceSupported();
    bool canCheck = await _auth.canCheckBiometrics;
    setState(() => _biometricsAvailable = isSupported && canCheck);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appLock = prefs.getBool('app_lock_enabled') ?? false;
      _smartLock = prefs.getBool('smart_lock_enabled') ?? false;
      _lastChecked = prefs.getString('last_update_check') ?? "Never";
    });
  }

  // --- ACTION: CHECK UPDATES (FAIL-SAFE LOGIC) ---
  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);

    // 1. Simulate small network delay for UX
    await Future.delayed(const Duration(seconds: 1));

    try {
      // 2. Try the Official Google Play In-App Update API
      AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        setState(() => _updateAvailable = true);
        // If update is available, we can trigger the native UI or just set the flag
        // The user can then click "Update Now" to go to store
      } else {
        setState(() => _updateAvailable = false);
        if (mounted) {
          _showSnack("Your app is fully up to date!", isSuccess: true);
        }
      }

      // Save Success Timestamp
      _updateTimestamp();
    } catch (e) {
      debugPrint("In-App Update Error (Expected in Debug): $e");

      // 3. FALLBACK: If API fails (Debug mode), check via Store Link
      // We assume if it failed, we can't know for sure, so we open the store
      // if the user requested the check manually.
      if (mounted) {
        _showSnack("Opening Play Store to check...", isSuccess: true);
        _launchPlayStore(); // Force open store so user can see for themselves
        _updateTimestamp(); // Mark as checked
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Future<void> _updateTimestamp() async {
    final now = DateTime.now();
    final formatted = DateFormat('MMM d, h:mm a').format(now);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_update_check', formatted);
    setState(() => _lastChecked = formatted);
  }

  // --- ACTION: LAUNCH PLAY STORE ---
  Future<void> _launchPlayStore() async {
    final Uri url = Uri.parse(_playStoreUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $_playStoreUrl';
      }
    } catch (e) {
      if (mounted) _showSnack("Could not open Play Store", isSuccess: false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // --- ACTION: TOGGLE LOCKS ---
  Future<void> _toggleLock(
    String key,
    bool currentValue,
    Function(bool) updateState,
  ) async {
    if (!currentValue) {
      try {
        bool authenticated = await _auth.authenticate(
          localizedReason: 'Authenticate to enable security',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (!authenticated) return;
      } catch (e) {
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, !currentValue);
    updateState(!currentValue);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(context);

    // Determine status color/icon based on update availability
    final statusColor = _updateAvailable
        ? const Color(0xFFE65100) // Orange for "Update Needed"
        : const Color(0xFF22C55E); // Green for "Good"

    final statusIcon = _updateAvailable
        ? Icons.download_rounded
        : Icons.check_circle_rounded;

    final statusText = _updateAvailable
        ? "New version available"
        : "App is up to date";

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
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
          "Settings",
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: SOFTWARE UPDATE ---
            Text(
              "SOFTWARE UPDATE",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Icon and Status Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusText,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Current: v$_currentVersion",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(height: 1, color: colors.border),
                  const SizedBox(height: 16),

                  // Bottom Row: Last Checked + Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Last Checked Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Last checked:",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _lastChecked,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Action Button
                      if (_isCheckingUpdate)
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _primaryColor,
                          ),
                        )
                      else if (_updateAvailable)
                        ElevatedButton(
                          onPressed: _launchPlayStore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            "Update Now",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        OutlinedButton(
                          onPressed: _checkForUpdates,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            "Check for Updates",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- SECTION: APPEARANCE ---
            Text(
              "APPEARANCE",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Container(
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
                  child: InkWell(
                    onTap: () => themeProvider.toggleTheme(),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? const Color(0xFF3B82F6).withOpacity(0.2)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return RotationTransition(
                                  turns: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Icon(
                                themeProvider.isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                key: ValueKey(themeProvider.isDarkMode),
                                color: themeProvider.isDarkMode
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFF59E0B),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dark Mode",
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  themeProvider.isDarkMode
                                      ? "Switch to light theme"
                                      : "Switch to dark theme",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 50,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: themeProvider.isDarkMode
                                  ? _primaryColor
                                  : Colors.grey.shade300,
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment: themeProvider.isDarkMode
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // --- SECTION 2: SECURITY ---
            Text(
              "SECURITY",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            if (!_biometricsAvailable)
              _buildErrorCard(
                "Biometric hardware not available on this device.",
              )
            else
              Container(
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
                    _buildSwitchTile(
                      context: context,
                      title: "App Lock",
                      subtitle: "Require FaceID/Fingerprint on startup",
                      icon: Icons.lock_outline_rounded,
                      value: _appLock,
                      onChanged: () => _toggleLock(
                        'app_lock_enabled',
                        _appLock,
                        (v) => setState(() => _appLock = v),
                      ),
                      isTop: true,
                    ),
                    Divider(height: 1, color: colors.border, indent: 56),
                    _buildSwitchTile(
                      context: context,
                      title: "Smart Lock",
                      subtitle: "Require auth to delete invoices",
                      icon: Icons.shield_outlined,
                      value: _smartLock,
                      onChanged: () => _toggleLock(
                        'smart_lock_enabled',
                        _smartLock,
                        (v) => setState(() => _smartLock = v),
                      ),
                      isBottom: true,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required VoidCallback onChanged,
    bool isTop = false,
    bool isBottom = false,
  }) {
    final colors = AppColors(context);
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.vertical(
        top: isTop ? const Radius.circular(16) : Radius.zero,
        bottom: isBottom ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: colors.icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: (_) => onChanged(),
                activeThumbColor: Colors.white,
                activeTrackColor: _primaryColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: colors.isDark
                    ? const Color(0xFF334155)
                    : Colors.grey.shade200,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Red 50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)), // Red 300
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                color: const Color(0xFFB91C1C),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
