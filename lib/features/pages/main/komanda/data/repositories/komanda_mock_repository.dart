import '../../domain/entities/komanda_entities.dart';

class KomandaMockRepository {
  static const _taco = 'assets/img/logo.png';

  List<KomandaProduct> get products => const [
        KomandaProduct(name: 'Taco de Carne', note: 'Sin cebolla', quantity: 2, price: 22, image: _taco),
        KomandaProduct(name: 'Taco de Costilla', note: 'Con todo', quantity: 1, price: 28, image: _taco),
        KomandaProduct(name: 'Taco de Pastor', note: 'Sin piña', quantity: 1, price: 22, image: _taco),
        KomandaProduct(name: 'Taco de Chicharrón', note: 'Con salsa verde', quantity: 1, price: 22, image: _taco),
        KomandaProduct(name: 'Taco de Buche', note: 'Con todo', quantity: 1, price: 22, image: _taco),
      ];

  KomandaOrder get currentOrder => KomandaOrder(
        folio: '#0012',
        tableNumber: 5,
        customerName: 'Juan Pérez',
        people: 2,
        type: 'Comer aquí',
        status: 'En preparación',
        time: '10:30 PM',
        date: '20/05/2024',
        note: 'Sin pico de gallo en los tacos de pastor.',
        products: products,
      );

  List<KomandaMetric> get metrics => const [
        KomandaMetric(title: 'Ventas hoy', value: r'$ 8,560.00', percent: '↗ 12.5%', icon: r'$'),
        KomandaMetric(title: 'Pedidos', value: '37', percent: '↗ 8.2%', icon: '▣'),
        KomandaMetric(title: 'Ticket promedio', value: r'$ 231.35', percent: '↗ 5.1%', icon: '▥'),
        KomandaMetric(title: 'Clientes hoy', value: '82', percent: '↗ 9.3%', icon: '👥'),
      ];
}
