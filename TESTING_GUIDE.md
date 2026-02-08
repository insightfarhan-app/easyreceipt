# Testing Guide for Purchase History Implementation

## Overview
This guide helps verify that the purchase history implementation works correctly.

## Prerequisites
- Flutter development environment set up
- EasyReceipt app installed on device/emulator
- Access to app settings

## Test Scenarios

### 1. Data Persistence Test ✅

**Objective**: Verify that purchase history persists when app is closed and reopened.

**Steps**:
1. Open the app
2. Create a new invoice with some test data:
   - Customer Name: "Test Customer"
   - Add 1-2 items
   - Save the invoice
3. Go to Invoice History and verify the invoice appears
4. **Close the app completely** (force stop or swipe away from recent apps)
5. Reopen the app
6. Go to Invoice History

**Expected Result**: 
- ✅ The test invoice should still be visible
- ✅ All data should be intact (customer name, items, total)

---

### 2. Edit with Smart Lock Test 🔐

**Objective**: Verify that editing requires authentication when Smart Lock is enabled.

**Steps**:
1. Go to Settings
2. Enable "Smart Lock" (requires biometric authentication to enable)
3. Go to Invoice History
4. Tap on an existing invoice
5. Tap the Edit button

**Expected Result**:
- ✅ Biometric authentication prompt should appear
- ✅ After successful authentication, edit form should open
- ✅ If authentication fails, edit should be canceled

**Verify Smart Lock Off**:
1. Go to Settings
2. Disable "Smart Lock" (requires authentication)
3. Go to Invoice History
4. Tap on an invoice and click Edit

**Expected Result**:
- ✅ Edit form should open immediately without authentication prompt

---

### 3. Delete with Smart Lock Test 🗑️

**Objective**: Verify that deleting requires authentication when Smart Lock is enabled.

**Steps**:
1. Go to Settings
2. Ensure "Smart Lock" is enabled
3. Go to Invoice History
4. Tap the delete icon (top right)
5. Select one or more invoices
6. Tap the delete button

**Expected Result**:
- ✅ Confirmation dialog should appear
- ✅ After confirming, biometric authentication prompt should appear
- ✅ After successful authentication, invoices should be deleted
- ✅ If authentication fails, deletion should be canceled

**Verify Smart Lock Off**:
1. Disable Smart Lock in Settings
2. Go to Invoice History
3. Delete an invoice

**Expected Result**:
- ✅ Only confirmation dialog appears (no authentication)
- ✅ Invoice is deleted after confirmation

---

### 4. Single Delete Test 🗑️

**Objective**: Verify deleting a single invoice works correctly.

**Steps**:
1. Go to Invoice History
2. Note the total count of invoices
3. Tap delete icon
4. Select ONE invoice
5. Tap delete and confirm (authenticate if Smart Lock is on)

**Expected Result**:
- ✅ Selected invoice is removed from list
- ✅ Total count decreases by 1
- ✅ Other invoices remain intact

---

### 5. Multiple Delete Test 🗑️🗑️

**Objective**: Verify deleting multiple invoices works correctly.

**Steps**:
1. Go to Invoice History (ensure at least 3 invoices exist)
2. Note the total count
3. Tap delete icon
4. Select 2 or more invoices
5. Tap delete and confirm (authenticate if Smart Lock is on)

**Expected Result**:
- ✅ All selected invoices are removed
- ✅ Count decreases by correct number
- ✅ Unselected invoices remain

---

### 6. Edit Invoice Test ✏️

**Objective**: Verify editing an invoice updates the data correctly.

**Steps**:
1. Go to Invoice History
2. Tap an invoice (authenticate if Smart Lock is on)
3. Tap Edit
4. Change customer name to "Edited Customer"
5. Change item quantity or add a new item
6. Save the invoice
7. Close and reopen the app
8. Go to Invoice History
9. Find and view the edited invoice

**Expected Result**:
- ✅ Customer name shows "Edited Customer"
- ✅ Items reflect the changes made
- ✅ Grand total is recalculated correctly
- ✅ Changes persist after app restart

---

### 7. Mark as Paid Test 💰

**Objective**: Verify marking a credit invoice as paid works correctly.

**Steps**:
1. Create a new invoice with Invoice Type: "Credit"
2. Go to Invoice History
3. Go to "Credit Sales" tab
4. Go to "Unpaid Bills" sub-tab
5. Find the invoice and tap "Pay Bill"
6. Confirm the payment

**Expected Result**:
- ✅ Invoice moves from "Unpaid Bills" to "Paid History"
- ✅ Status changes to "Paid"
- ✅ Change persists after app restart

---

### 8. Search Test 🔍

**Objective**: Verify search functionality works correctly.

**Steps**:
1. Go to Invoice History
2. Ensure you have invoices with different customer names
3. Type a customer name in the search box
4. Try typing part of an invoice ID

**Expected Result**:
- ✅ Only matching invoices are displayed
- ✅ Search works for both customer name and invoice ID
- ✅ Clearing search shows all invoices again

---

### 9. Filter by Date Test 📅

**Objective**: Verify date filtering works correctly.

**Steps**:
1. Go to Invoice History
2. Tap the date filter icon
3. Select a date range
4. Apply the filter

**Expected Result**:
- ✅ Only invoices within the date range are shown
- ✅ Count reflects filtered results
- ✅ Clearing filter shows all invoices

---

### 10. DayBook Profit Calculation Test 📊

**Objective**: Verify that purchase prices are used for profit calculations.

**Steps**:
1. Create an invoice with items that have both selling price and purchase price
2. Go to DayBook & Profits from the home screen
3. Select "All Time" filter
4. Find your invoice in the list

**Expected Result**:
- ✅ Profit = Revenue - Cost (where cost is sum of purchase prices)
- ✅ Profit percentage is calculated correctly
- ✅ Summary card shows total profit accurately

---

### 11. Cash vs Credit Test 💵

**Objective**: Verify Cash and Credit invoices are categorized correctly.

**Steps**:
1. Create a Cash invoice
2. Create a Credit invoice  
3. Go to Invoice History
4. Check "Cash Sales" tab
5. Check "Credit Sales" tab

**Expected Result**:
- ✅ Cash invoice appears only in Cash Sales tab
- ✅ Credit invoice appears only in Credit Sales tab
- ✅ Counts are accurate for each type

---

### 12. Quotation Conversion Test 🔄

**Objective**: Verify converting quotation to invoice works with the new service.

**Steps**:
1. Create a quotation
2. Go to "Convert to Sale" from quotation page
3. Select the quotation
4. Choose invoice type (Cash/Credit)
5. Convert to invoice
6. Go to Invoice History

**Expected Result**:
- ✅ New invoice appears in history
- ✅ Invoice has all data from quotation
- ✅ Invoice persists after app restart

---

### 13. Reports Test 📈

**Objective**: Verify reports still work with the new service.

**Steps**:
1. Create several invoices with different dates and amounts
2. Go to Reports from home screen
3. Try different filters (Daily, Weekly, Monthly)
4. Check the chart and statistics

**Expected Result**:
- ✅ All invoices are included in calculations
- ✅ Filters work correctly
- ✅ Chart displays data accurately
- ✅ Export/Share functions work (if applicable)

---

## Quick Regression Test Checklist

Run through this checklist for a quick verification:

- [ ] Create new invoice → Close app → Reopen → Invoice exists
- [ ] Edit invoice with Smart Lock ON → Authentication required
- [ ] Edit invoice with Smart Lock OFF → No authentication
- [ ] Delete invoice with Smart Lock ON → Authentication required
- [ ] Delete invoice with Smart Lock OFF → No authentication
- [ ] Delete multiple invoices → All selected are removed
- [ ] Mark credit invoice as paid → Moves to Paid History
- [ ] Search by customer name → Correct results
- [ ] Filter by date range → Correct results
- [ ] DayBook shows profit calculations correctly
- [ ] Cash invoices appear in Cash Sales tab only
- [ ] Credit invoices appear in Credit Sales tab only
- [ ] Convert quotation to invoice → Appears in history

## Bug Reporting

If you encounter any issues during testing, please report them with:

1. **Steps to Reproduce**: Exact steps that caused the issue
2. **Expected Behavior**: What should have happened
3. **Actual Behavior**: What actually happened
4. **Device Info**: Device model, OS version, app version
5. **Screenshots**: If applicable

## Performance Testing

Monitor the following during testing:

- **App startup time**: Should not be noticeably slower
- **List loading**: Invoice history should load quickly (< 2 seconds for 100+ invoices)
- **Search response**: Should filter results instantly
- **Memory usage**: Should remain stable (check in device settings)

## Success Criteria

All tests should pass with these results:
- ✅ Data persists across app restarts
- ✅ Smart Lock integration works correctly
- ✅ Edit and delete operations function properly
- ✅ No data loss or corruption
- ✅ Performance remains acceptable
- ✅ No crashes or errors

---

## Notes

- Some tests require enabling/disabling Smart Lock, which requires biometric authentication
- Make sure you have sample invoices with different dates, types, and statuses
- Test on both Android and iOS if possible
- Test with both light and dark themes
