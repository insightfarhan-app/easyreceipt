import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final _auth = LocalAuthentication();

  /// 🟢 Call this when the app starts (in main.dart)
  static Future<bool> requireAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('app_lock_enabled') ?? false;

    if (!enabled) return true; // No lock needed

    return await _authenticate("Unlock EasyInvoice");
  }

  /// 🟢 Call this before Deleting or Editing (Smart Lock)
  static Future<bool> requireSmartLock() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('smart_lock_enabled') ?? false;

    if (!enabled) return true; // Smart lock is off, allow action

    return await _authenticate("Verify your identity to proceed");
  }

  /// Internal helper to trigger the fingerprint prompt
  static Future<bool> _authenticate(String reason) async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return true; // Fallback if no hardware support

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
