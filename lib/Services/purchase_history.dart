import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:EasyInvoice/Drawer/Security/security_service.dart';

/// Service for managing purchase/invoice history with SharedPreferences
/// This ensures all purchase data persists across app restarts
class PurchaseHistoryService {
  static const String _historyKey = "invoice_history";

  /// Get all purchase history from SharedPreferences
  /// Returns a list of invoice/purchase records
  static Future<List<Map<String, dynamic>>> getAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    
    List<Map<String, dynamic>> parsed = [];
    for (String item in list) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          parsed.add(decoded);
        }
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }
    
    return parsed;
  }

  /// Get raw string list from SharedPreferences
  /// Useful for operations that need to work with the original format
  static Future<List<String>> getRawHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  /// Add a new purchase/invoice to history
  /// If an invoice with the same ID exists, it will be updated
  static Future<bool> addOrUpdatePurchase(Map<String, dynamic> invoiceData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];
      int existingIndex = -1;

      // Check if invoice already exists
      for (int i = 0; i < list.length; i++) {
        try {
          final existing = jsonDecode(list[i]);
          if (existing['invoiceId'] == invoiceData['invoiceId']) {
            existingIndex = i;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      // Add timestamp
      invoiceData["savedAt"] = DateTime.now().toIso8601String();

      // Update existing or add new
      if (existingIndex != -1) {
        list[existingIndex] = jsonEncode(invoiceData);
      } else {
        list.add(jsonEncode(invoiceData));
      }

      await prefs.setStringList(_historyKey, list);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a single purchase/invoice by its ID and savedAt timestamp
  /// Requires smart lock authentication if enabled in settings
  static Future<bool> deletePurchase(
    String invoiceId,
    String savedAt, {
    bool skipSmartLock = false,
  }) async {
    // Check smart lock unless explicitly skipped
    if (!skipSmartLock) {
      bool authorized = await SecurityService.requireSmartLock();
      if (!authorized) {
        return false;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];

      list.removeWhere((rawString) {
        try {
          final decoded = jsonDecode(rawString);
          return decoded['invoiceId'] == invoiceId &&
              decoded['savedAt'] == savedAt;
        } catch (e) {
          return false;
        }
      });

      await prefs.setStringList(_historyKey, list);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete multiple purchases/invoices by their unique keys
  /// Requires smart lock authentication if enabled in settings
  static Future<bool> deletePurchases(
    List<String> uniqueKeys, {
    bool skipSmartLock = false,
  }) async {
    // Check smart lock unless explicitly skipped
    if (!skipSmartLock) {
      bool authorized = await SecurityService.requireSmartLock();
      if (!authorized) {
        return false;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];

      list.removeWhere((rawString) {
        try {
          final decoded = jsonDecode(rawString);
          String key = "${decoded['invoiceId']}_${decoded['savedAt']}";
          return uniqueKeys.contains(key);
        } catch (e) {
          return false;
        }
      });

      await prefs.setStringList(_historyKey, list);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Edit/Update a purchase/invoice
  /// Requires smart lock authentication if enabled in settings
  static Future<bool> editPurchase(
    Map<String, dynamic> updatedData, {
    bool skipSmartLock = false,
  }) async {
    // Check smart lock unless explicitly skipped
    if (!skipSmartLock) {
      bool authorized = await SecurityService.requireSmartLock();
      if (!authorized) {
        return false;
      }
    }

    // Use addOrUpdatePurchase since it handles both add and update
    return await addOrUpdatePurchase(updatedData);
  }

  /// Mark an invoice as paid (for credit sales)
  static Future<bool> markAsPaid(String invoiceId, String savedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];
      List<String> updatedList = [];

      for (String itemStr in list) {
        try {
          Map<String, dynamic> itemMap = jsonDecode(itemStr);
          if (itemMap['invoiceId'] == invoiceId &&
              itemMap['savedAt'] == savedAt) {
            itemMap['status'] = 'Paid';
            updatedList.add(jsonEncode(itemMap));
          } else {
            updatedList.add(itemStr);
          }
        } catch (e) {
          updatedList.add(itemStr);
        }
      }

      await prefs.setStringList(_historyKey, updatedList);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all purchase history
  /// Requires smart lock authentication if enabled in settings
  static Future<bool> clearAllHistory({bool skipSmartLock = false}) async {
    // Check smart lock unless explicitly skipped
    if (!skipSmartLock) {
      bool authorized = await SecurityService.requireSmartLock();
      if (!authorized) {
        return false;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get purchase history count
  static Future<int> getHistoryCount() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    return list.length;
  }

  /// Search purchase history by query string
  /// Searches in customer name and invoice ID
  static Future<List<Map<String, dynamic>>> searchHistory(String query) async {
    final allHistory = await getAllHistory();
    
    if (query.trim().isEmpty) {
      return allHistory;
    }

    final q = query.toLowerCase();
    return allHistory.where((invoice) {
      final invoiceId = invoice['invoiceId']?.toString().toLowerCase() ?? '';
      final customerName = invoice['customerName']?.toString().toLowerCase() ?? '';
      return invoiceId.contains(q) || customerName.contains(q);
    }).toList();
  }

  /// Get history filtered by date range
  static Future<List<Map<String, dynamic>>> getHistoryByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final allHistory = await getAllHistory();
    
    return allHistory.where((invoice) {
      final savedAt = invoice['savedAt'];
      final invoiceDate = invoice['invoiceDate'];
      
      DateTime? dt;
      if (savedAt != null) {
        dt = DateTime.tryParse(savedAt);
      } else if (invoiceDate != null) {
        dt = DateTime.tryParse(invoiceDate);
      }
      
      if (dt == null) return false;
      
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
  }

  /// Get history filtered by type (Cash or Credit)
  static Future<List<Map<String, dynamic>>> getHistoryByType(String type) async {
    final allHistory = await getAllHistory();
    
    return allHistory.where((invoice) {
      final invoiceType = invoice['invoiceType'] ?? 'Credit';
      return invoiceType == type;
    }).toList();
  }

  /// Get credit invoices filtered by payment status
  static Future<List<Map<String, dynamic>>> getCreditHistoryByStatus(
    String status,
  ) async {
    final allHistory = await getAllHistory();
    
    return allHistory.where((invoice) {
      final invoiceType = invoice['invoiceType'] ?? 'Credit';
      final invoiceStatus = invoice['status'] ?? 'Unpaid';
      return invoiceType == 'Credit' && invoiceStatus == status;
    }).toList();
  }
}
