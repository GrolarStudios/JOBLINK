import 'package:flutter/material.dart';
import '../widgets/komanda_widgets.dart';
import 'komanda_ticket_settings_page.dart';
import 'komanda_products_admin_page.dart';

class KomandaAdminPage extends StatelessWidget {
  const KomandaAdminPage({super.key});

  @override
  Widget build(BuildContext context) => KomandaPhoneFrame(
        child: Column(
          children: [
            const KomandaHeader(title: 'Herramientas'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _Tile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Productos',
                    text: 'Administra productos, categorías, configuraciones y paquetes',
                    page: KomandaProductsAdminPage(),
                  ),
                  _Tile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Diseño del ticket',
                    text: 'Configura datos, logo y formato del ticket',
                    page: KomandaTicketSettingsPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title, text;
  final Widget page;
  const _Tile({required this.icon, required this.title, required this.text, required this.page});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(text),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        ),
      );
}
