import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/routes/route_names.dart';
import '../../core/komanda_theme.dart';
import '../../core/komanda_permissions.dart';
import '../../core/utils/komanda_order_sections.dart';
import '../../data/datasources/komanda_remote_datasource.dart';
import '../../domain/entities/komanda_order.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';
import 'komanda_history_page.dart';
import 'komanda_products_admin_page.dart';
import 'komanda_tables_overview_page.dart';
import 'komanda_ticket_settings_page.dart';
import 'komanda_tables_admin_page.dart';
import 'komanda_users_admin_page.dart';
import 'komanda_finances_page.dart';
import '../waiter_management/pages/komanda_waiters_page.dart';
import '../chef/pages/komanda_chef_orders_page.dart';
import 'komanda_kitchen_settings_page.dart';

class KomandaDashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final String restaurantId;
  final KomandaRemoteDataSource remote;
  final Future<void> Function() onLogout;

  const KomandaDashboardPage({
    super.key,
    this.username = '',
    required this.role,
    this.restaurantId = '',
    required this.remote,
    required this.onLogout,
  });

  @override
  State<KomandaDashboardPage> createState() => _KomandaDashboardPageState();
}

class _KomandaDashboardPageState extends State<KomandaDashboardPage> {
  bool _showKitchenStations = true;
  String get _kitchenVisibilityKey => 'komanda_show_kitchen_stations_${widget.restaurantId}';

  @override
  void initState() {
    super.initState();
    _loadKitchenVisibility();
  }

  Future<void> _loadKitchenVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _showKitchenStations = prefs.getBool(_kitchenVisibilityKey) ?? true);
  }

  Future<void> _setKitchenVisibility(bool visible) async {
    setState(() => _showKitchenStations = visible);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kitchenVisibilityKey, visible);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        // El globo refleja pedidos que requieren atención, no simplemente
        // estados antiguos que pudieron quedar después de cobrar.
        final activeOrders = state.orders.where((order) {
          if (order.status == KomandaOrderStatus.completed ||
              order.status == KomandaOrderStatus.cancelled ||
              order.status == KomandaOrderStatus.atTable) {
            return false;
          }
          // Para llevar y domicilio se consideran atendidos al cobrar.
          if (order.orderType != KomandaOrderType.dineIn && order.isPaid) {
            return false;
          }
          return true;
        }).toList();
        final pending = activeOrders
            .where((o) => o.status == KomandaOrderStatus.pending)
            .length;
        final preparing = activeOrders
            .where((o) => o.status == KomandaOrderStatus.preparing)
            .length;
        final ready = activeOrders
            .where((o) =>
                o.status == KomandaOrderStatus.waiting ||
                o.status == KomandaOrderStatus.delivering)
            .length;
        final kitchenActiveOrders = state.orders.where(
          (o) =>
              o.status == KomandaOrderStatus.pending ||
              o.status == KomandaOrderStatus.preparing,
        );
        final kitchenTortas = kitchenActiveOrders.where(
          (o) => KomandaOrderSections.itemsFor(
            o.items,
            KomandaOrderSection.tortas,
          ).isNotEmpty,
        ).length;
        final kitchenTacos = kitchenActiveOrders.where(
          (o) => KomandaOrderSections.itemsFor(
            o.items,
            KomandaOrderSection.tacos,
          ).isNotEmpty,
        ).length;
        final greeting = _Greeting.now(widget.username);
        final restaurantName = state.ticketConfig.businessName.trim().isEmpty
            ? 'Komanda'
            : state.ticketConfig.businessName.trim();

        return KomandaPhoneFrame(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                          child: Row(
                            children: [
                              _RestaurantIdentityLogo(logoBase64: state.ticketConfig.logoBase64),
                              const SizedBox(width: 12),
                              Expanded(child: Text(restaurantName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: KomandaTheme.text))),
                              if (!KomandaPermissions.isWaiter(widget.role)) IconButton(
                                tooltip: 'Tickets',
                                onPressed: () => Navigator.pushNamed(context, RouteNames.komandaHistory),
                                icon: const Icon(Icons.receipt_long_rounded, color: KomandaTheme.purple),
                              ),
                              if (widget.restaurantId.trim() != '1') IconButton(
                                tooltip: 'Disponibilidad de mesas',
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KomandaTablesOverviewPage())),
                                icon: const Icon(Icons.table_restaurant_rounded, color: KomandaTheme.purple),
                              ),
                              if (KomandaPermissions.isOrderTaker(widget.role) || KomandaPermissions.isWaiter(widget.role))
                                IconButton(
                                  tooltip: 'Mi perfil',
                                  onPressed: () => Navigator.pushNamed(context, '/komanda/profile'),
                                  icon: const Icon(Icons.account_circle_rounded, color: KomandaTheme.purple, size: 26),
                                ),
                              IconButton(
                                tooltip: 'Actualizar datos',
                                onPressed: () => context.read<KomandaBloc>().add(const KomandaRefreshed(showLoading: false)),
                                icon: const Icon(Icons.refresh_rounded, color: KomandaTheme.purple, size: 26),
                              ),
                              if (KomandaPermissions.canManageRestaurant(widget.role) && !KomandaPermissions.isWaiter(widget.role))
                                IconButton(
                                  tooltip: 'Herramientas del restaurante',
                                  onPressed: () => _openTools(context),
                                  icon: const Icon(Icons.tune_rounded, color: KomandaTheme.purple, size: 28),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                          child: Text(
                            '${greeting.emoji} ${greeting.text} ${greeting.name}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KomandaTheme.text),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _RestaurantFlowCard(
                          role: widget.role,
                          showKitchenStations: _showKitchenStations,
                          pending: pending,
                          preparing: preparing,
                          ready: ready,
                          pendingCalls: state.pendingCallsList.length,
                          kitchenTortas: kitchenTortas,
                          kitchenTacos: kitchenTacos,
                          onNewOrder: () => Navigator.pushNamed(context, RouteNames.komandaNewOrderTable),
                          onOrders: () async {
                            await Navigator.pushNamed(context, '/komanda/order-status');
                            if (context.mounted) {
                              context.read<KomandaBloc>().add(const KomandaRefreshed(showLoading: false));
                            }
                          },
                          onKitchenTortas: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KomandaChefOrdersPage(remote: widget.remote))),
                          onKitchenTacos: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KomandaChefOrdersPage(remote: widget.remote))),
                          onCalls: () => Navigator.pushNamed(context, RouteNames.komandaChefOrders),
                        ),
],
                    ),
                  ),
              ),
              if (KomandaPermissions.isAdmin(widget.role)) const BottomNavMock(index: 0),
            ],
          ),
        );
      },
    );
  }


  static DateTime _historyDate(KomandaOrder order) {
    return order.deliveredAt ??
        order.paidAt ??
        order.readyAt ??
        order.createdAt;
  }

  void _openTools(BuildContext context) {
    if (!KomandaPermissions.canManageRestaurant(widget.role) && !KomandaPermissions.isWaiter(widget.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta opción es exclusiva del administrador.'),
        ),
      );
      return;
    }

    if (KomandaPermissions.isWaiter(widget.role)) {
      Navigator.pushNamed(context, '/komanda/profile');
      return;
    }

    final tools = <_RestaurantTool>[
      _RestaurantTool(
        icon: Icons.account_circle_rounded,
        title: 'Perfil',
        onTap: () => Navigator.pushNamed(context, '/komanda/profile'),
      ),
      _RestaurantTool(
        icon: Icons.people_alt_rounded,
        title: 'Usuarios',
        onTap: () => _push(context, KomandaUsersAdminPage(remote: widget.remote)),
      ),
      _RestaurantTool(
        icon: Icons.inventory_2_rounded,
        title: 'Productos',
        onTap: () => _push(context, KomandaProductsAdminPage(remote: widget.remote)),
      ),
      _RestaurantTool(
        icon: Icons.visibility_outlined,
        title: _showKitchenStations ? 'Ocultar puestos en inicio' : 'Mostrar puestos en inicio',
        onTap: () => _setKitchenVisibility(!_showKitchenStations),
      ),
      _RestaurantTool(
        icon: Icons.soup_kitchen_rounded,
        title: 'Configurar cocina',
        onTap: () => _push(context, KomandaKitchenSettingsPage(remote: widget.remote)),
      ),
      _RestaurantTool(
        icon: Icons.receipt_long_rounded,
        title: 'Ticket',
        onTap: () => _push(context, const KomandaTicketSettingsPage()),
      ),
      if (widget.restaurantId != '2') ...[
        _RestaurantTool(
          icon: Icons.table_restaurant_rounded,
          title: 'Mesas',
          onTap: () => _push(context, const KomandaTablesAdminPage()),
        ),
        _RestaurantTool(
          icon: Icons.visibility_outlined,
          title: 'Disponibilidad de mesas',
          onTap: () => _push(context, const KomandaTablesOverviewPage()),
        ),
        _RestaurantTool(
          icon: Icons.badge_rounded,
          title: 'Meseros',
          onTap: () => _push(context, const KomandaWaitersPage()),
        ),
      ],
      _RestaurantTool(
        icon: Icons.payments_rounded,
        title: 'Cobros',
        onTap: () => Navigator.pushNamed(context, '/komanda/payments'),
      ),
      _RestaurantTool(
        icon: Icons.point_of_sale_rounded,
        title: 'Corte',
        onTap: () => Navigator.pushNamed(context, '/komanda/cash-close'),
      ),
      _RestaurantTool(
        icon: Icons.insights_rounded,
        title: 'Rendimiento',
        onTap: () => Navigator.pushNamed(context, '/komanda/performance'),
      ),
      _RestaurantTool(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Finanzas',
        onTap: () => _push(context, KomandaFinancesPage(remote: widget.remote)),
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 24,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: KomandaTheme.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: KomandaTheme.purple.withOpacity(.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        color: KomandaTheme.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Herramientas del restaurante',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: KomandaTheme.text,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 650 ? 4 : constraints.maxWidth >= 370 ? 3 : 2;
                    final sections = <({String title, IconData icon, List<_RestaurantTool> items})>[
                      (title: 'Personal', icon: Icons.manage_accounts_outlined, items: tools.sublist(0, 2)),
                      (title: 'Productos y configuración', icon: Icons.inventory_2_outlined, items: tools.sublist(2, 5)),
                      (title: 'Restaurante', icon: Icons.restaurant_outlined, items: widget.restaurantId != '2' ? tools.sublist(5, 8) : <_RestaurantTool>[]),
                      (title: 'Dinero y resultados', icon: Icons.account_balance_wallet_outlined, items: tools.sublist(widget.restaurantId != '2' ? 8 : 5)),
                    ];
                    return SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (final section in sections)
                          if (section.items.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                              child: Row(children: [
                                Icon(section.icon, color: KomandaTheme.purple, size: 19),
                                const SizedBox(width: 8),
                                Text(section.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
                              ]),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.35,
                              ),
                              itemCount: section.items.length,
                              itemBuilder: (context, index) {
                                final tool = section.items[index];
                                return Material(
                                  color: KomandaTheme.purple.withOpacity(.045),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      tool.onTap();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: KomandaTheme.purple.withOpacity(.12)),
                                      ),
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(tool.icon, color: KomandaTheme.purple, size: 25),
                                        const SizedBox(height: 8),
                                        Text(tool.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KomandaTheme.text)),
                                      ]),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                      ]),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(.22)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _confirmLogout(context);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Seguro que deseas cerrar la sesión actual?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await widget.onLogout();
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _RestaurantTool {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _RestaurantTool({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _RestaurantIdentityLogo extends StatelessWidget {
  final String logoBase64;

  const _RestaurantIdentityLogo({required this.logoBase64});

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      if (logoBase64.trim().isNotEmpty) {
        bytes = Uint8List.fromList(base64Decode(logoBase64));
      }
    } catch (_) {
      bytes = null;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: KomandaTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? const Center(child: Text('K', style: TextStyle(color: KomandaTheme.purple, fontSize: 29, fontWeight: FontWeight.w900)))
          : Image.memory(bytes, fit: BoxFit.cover),
    );
  }
}

class _Greeting {
  final String text;
  final String emoji;
  final String name;

  const _Greeting({
    required this.text,
    required this.emoji,
    required this.name,
  });

  factory _Greeting.now(String username) {
    final hour = DateTime.now().hour;
    final cleanName = username.trim().isEmpty ? 'equipo' : username.trim();

    if (hour < 12) {
      return _Greeting(text: '¡Buenos días!', emoji: '☀️', name: cleanName);
    }
    if (hour < 19) {
      return _Greeting(text: '¡Buenas tardes!', emoji: '🌤️', name: cleanName);
    }
    return _Greeting(text: '¡Buenas noches!', emoji: '🌙', name: cleanName);
  }
}

class _RestaurantFlowCard extends StatelessWidget {
  final String role;
  final bool showKitchenStations;
  final int pending;
  final int preparing;
  final int ready;
  final int pendingCalls;
  final int kitchenTortas;
  final int kitchenTacos;
  final VoidCallback onNewOrder;
  final VoidCallback onOrders;
  final VoidCallback onKitchenTortas;
  final VoidCallback onKitchenTacos;
  final VoidCallback onCalls;

  const _RestaurantFlowCard({
    required this.role,
    required this.showKitchenStations,
    required this.pending,
    required this.preparing,
    required this.ready,
    required this.pendingCalls,
    required this.kitchenTortas,
    required this.kitchenTacos,
    required this.onNewOrder,
    required this.onOrders,
    required this.onKitchenTortas,
    required this.onKitchenTacos,
    required this.onCalls,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <_RestaurantFlowAction>[
      if (KomandaPermissions.canCreateOrders(role))
        _RestaurantFlowAction(
          icon: Icons.add_shopping_cart_rounded,
          title: 'Tomar pedido',
          subtitle: 'Crear una nueva orden',
          color: const Color(0xFFEA6B0A),
          onTap: onNewOrder,
        ),
      if (KomandaPermissions.canViewOrderStatus(role))
        _RestaurantFlowAction(
          icon: Icons.receipt_long_rounded,
          title: 'Pedidos',
          subtitle: 'Ver preparación, pendientes y entregados',
          badge: pending + preparing + ready,
          color: const Color(0xFF16856C),
          onTap: onOrders,
        ),
      if (showKitchenStations && KomandaPermissions.canUseKitchen(role)) ...[
        _RestaurantFlowAction(icon: Icons.lunch_dining_rounded, title: 'Puestos de cocina', subtitle: 'Seleccionar un puesto configurado', badge: kitchenTortas, color: const Color(0xFF2865C7), onTap: onKitchenTortas),
      ],
      if (false && KomandaPermissions.canUseWaiterArea(role))
        _RestaurantFlowAction(
          icon: Icons.notifications_active_rounded,
          title: 'Entrega',
          subtitle: '$ready listos · $pendingCalls llamados',
          badge: ready + pendingCalls,
          color: const Color(0xFF8054BD),
          onTap: onCalls,
        ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 780
              ? 4
              : constraints.maxWidth >= 500
                  ? 3
                  : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: action.color.withOpacity(.20)),
                      boxShadow: [
                        BoxShadow(
                          color: action.color.withOpacity(.035),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        if (action.badge > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: action.color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${action.badge}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: action.color.withOpacity(.10),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(action.icon, color: action.color, size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                action.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: KomandaTheme.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RestaurantFlowAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final int badge;
  final Color color;
  final VoidCallback onTap;

  const _RestaurantFlowAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge = 0,
    required this.color,
    required this.onTap,
  });
}

class _StatusBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double marginRight;

  const _StatusBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.marginRight = 8,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: marginRight),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: KomandaTheme.softText,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 27,
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Urgent extends StatelessWidget {
  final String table;
  final String text;
  final Color color;

  const _Urgent({
    required this.table,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(.12),
              child: Icon(Icons.notifications_none, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: KomandaTheme.text,
                    ),
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      );
}
