# Purchase History Service

## Overview
The `PurchaseHistoryService` is a centralized service for managing invoice/purchase history in the EasyInvoice app. It handles all data persistence operations using SharedPreferences and integrates with the Smart Lock security feature.

## Features

### ✅ Data Persistence
- All purchase/invoice data is stored in SharedPreferences
- Data persists across app restarts
- Automatic timestamp management

### 🔐 Smart Lock Integration
- Delete operations require Smart Lock authentication (if enabled)
- Edit operations require Smart Lock authentication (if enabled)
- Can be bypassed programmatically when needed

### 📊 CRUD Operations
- **Create**: Add new invoices to history
- **Read**: Retrieve all or filtered history
- **Update**: Edit existing invoices
- **Delete**: Remove single or multiple invoices

## Usage

### Import the Service
```dart
import 'package:EasyInvoice/Services/purchase_history.dart';
```

### Get All History
```dart
// Get parsed history as List<Map<String, dynamic>>
List<Map<String, dynamic>> history = await PurchaseHistoryService.getAllHistory();

// Get raw string list (for compatibility)
List<String> rawHistory = await PurchaseHistoryService.getRawHistory();
```

### Add or Update Invoice
```dart
Map<String, dynamic> invoiceData = {
  'invoiceId': 'INV-0001',
  'customerName': 'John Doe',
  'grandTotal': 100.0,
  'items': [...],
  // ... other fields
};

bool success = await PurchaseHistoryService.addOrUpdatePurchase(invoiceData);
```

### Delete Invoice (with Smart Lock)
```dart
// Delete single invoice
bool success = await PurchaseHistoryService.deletePurchase(
  'INV-0001',
  '2024-01-01T12:00:00.000Z',
);

// Delete multiple invoices
List<String> keys = ['INV-0001_2024-01-01T12:00:00.000Z', ...];
bool success = await PurchaseHistoryService.deletePurchases(keys);

// Skip smart lock (use with caution)
bool success = await PurchaseHistoryService.deletePurchase(
  'INV-0001',
  '2024-01-01T12:00:00.000Z',
  skipSmartLock: true,
);
```

### Edit Invoice (with Smart Lock)
```dart
Map<String, dynamic> updatedData = {
  'invoiceId': 'INV-0001',
  'customerName': 'Jane Doe',  // Updated
  // ... other fields
};

bool success = await PurchaseHistoryService.editPurchase(updatedData);
```

### Mark Invoice as Paid
```dart
bool success = await PurchaseHistoryService.markAsPaid(
  'INV-0001',
  '2024-01-01T12:00:00.000Z',
);
```

### Search and Filter

#### Search by Query
```dart
List<Map<String, dynamic>> results = await PurchaseHistoryService.searchHistory('John');
```

#### Filter by Date Range
```dart
DateTime start = DateTime(2024, 1, 1);
DateTime end = DateTime(2024, 12, 31);
List<Map<String, dynamic>> results = await PurchaseHistoryService.getHistoryByDateRange(start, end);
```

#### Filter by Type (Cash/Credit)
```dart
List<Map<String, dynamic>> cashInvoices = await PurchaseHistoryService.getHistoryByType('Cash');
List<Map<String, dynamic>> creditInvoices = await PurchaseHistoryService.getHistoryByType('Credit');
```

#### Filter by Payment Status
```dart
List<Map<String, dynamic>> unpaidInvoices = await PurchaseHistoryService.getCreditHistoryByStatus('Unpaid');
List<Map<String, dynamic>> paidInvoices = await PurchaseHistoryService.getCreditHistoryByStatus('Paid');
```

### Get History Count
```dart
int count = await PurchaseHistoryService.getHistoryCount();
```

### Clear All History (with Smart Lock)
```dart
bool success = await PurchaseHistoryService.clearAllHistory();
```

## Data Structure

### Invoice/Purchase Object
```dart
{
  'invoiceId': 'INV-0001',           // Unique invoice ID
  'customerName': 'John Doe',         // Customer name
  'customerPhone': '+1234567890',     // Customer phone
  'customerAddress': '123 Main St',   // Customer address
  'invoiceDate': '01/01/2024',        // Invoice date (DD/MM/YYYY)
  'savedAt': '2024-01-01T12:00:00.000Z', // Auto-generated timestamp
  'invoiceType': 'Cash',              // 'Cash' or 'Credit'
  'status': 'Paid',                   // 'Paid' or 'Unpaid'
  'items': [                          // List of items
    {
      'description': 'Item 1',
      'qty': '2',
      'price': '50.0',
      'purchasePrice': '30.0',        // Hidden purchase price for profit calc
      'amount': '100.0'
    }
  ],
  'subtotal': 100.0,                  // Subtotal amount
  'tax': 10.0,                        // Tax amount
  'discount': 5.0,                    // Discount amount
  'grandTotal': 105.0,                // Final total
  'convertedFrom': 'QUOTE-0001'       // Optional: If converted from quotation
}
```

## Smart Lock Behavior

The Smart Lock feature is controlled by the `smart_lock_enabled` setting in SharedPreferences:

- When **enabled**: User must authenticate (fingerprint/face ID) before:
  - Deleting invoices
  - Editing invoices
  - Clearing all history

- When **disabled**: Operations proceed without authentication

The service automatically checks and enforces the Smart Lock setting for sensitive operations.

## Migration from Direct SharedPreferences

If you were previously using direct SharedPreferences calls:

### Before
```dart
final prefs = await SharedPreferences.getInstance();
final list = prefs.getStringList("invoice_history") ?? [];
```

### After
```dart
final list = await PurchaseHistoryService.getRawHistory();
// or
final parsed = await PurchaseHistoryService.getAllHistory();
```

## Error Handling

All methods return boolean values indicating success/failure:
- `true`: Operation completed successfully
- `false`: Operation failed (authentication failed, error occurred, etc.)

For read operations, empty lists are returned on error.

## Notes

- The service uses the key `"invoice_history"` in SharedPreferences
- Timestamps are automatically added/updated with `savedAt` field
- Unique invoice identification uses combination of `invoiceId` and `savedAt`
- All operations are asynchronous
