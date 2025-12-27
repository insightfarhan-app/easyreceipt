import 'package:flutter/foundation.dart';

class InvoiceItem {
  String name;
  int qty;
  double price;

  InvoiceItem({required this.name, required this.qty, required this.price});

  double get total => qty * price;

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'price': price};

  static InvoiceItem fromJson(Map<String, dynamic> j) => InvoiceItem(
    name: j['name'],
    qty: j['qty'],
    price: (j['price'] as num).toDouble(),
  );
}

class InvoiceItemsProvider extends ChangeNotifier {
  final List<InvoiceItem> items = [];

  void addItem(InvoiceItem item) {
    if (items.length >= 20) return;
    items.add(item);
    notifyListeners();
  }

  void updateItem(int index, InvoiceItem item) {
    if (index < 0 || index >= items.length) return;
    items[index] = item;
    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }

  double subtotal() => items.fold(0.0, (s, it) => s + it.total);
}
