class KomandaProduct {
  final String name;
  final String note;
  final int quantity;
  final double price;
  final String image;

  const KomandaProduct({
    required this.name,
    required this.note,
    required this.quantity,
    required this.price,
    required this.image,
  });

  double get total => quantity * price;
}

class KomandaOrder {
  final String folio;
  final int tableNumber;
  final String customerName;
  final int people;
  final String type;
  final String status;
  final String time;
  final String date;
  final String note;
  final List<KomandaProduct> products;

  const KomandaOrder({
    required this.folio,
    required this.tableNumber,
    required this.customerName,
    required this.people,
    required this.type,
    required this.status,
    required this.time,
    required this.date,
    required this.note,
    required this.products,
  });

  double get subtotal => products.fold(0, (sum, item) => sum + item.total);
  double get discount => 0;
  double get total => subtotal - discount;
}

class KomandaMetric {
  final String title;
  final String value;
  final String percent;
  final String icon;

  const KomandaMetric({
    required this.title,
    required this.value,
    required this.percent,
    required this.icon,
  });
}
