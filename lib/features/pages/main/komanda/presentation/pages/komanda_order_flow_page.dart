import '../shared/widgets/komanda_touch_keyboard.dart';
import '../../core/utils/komanda_daily_folio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/routes/route_names.dart';
import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../domain/entities/komanda_entities.dart' as ui;
import '../../domain/entities/komanda_product.dart';
import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/komanda_waiter.dart';
import 'komanda_detail_page.dart';
import 'komanda_tables_overview_page.dart';
import 'komanda_tables_admin_page.dart';
import '../waiter_management/pages/komanda_waiters_page.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';
import '../shared/widgets/komanda_item_detail_view.dart';
import '../shared/widgets/komanda_payment_dialog.dart';
import '../shared/widgets/komanda_order_sections_view.dart';
import '../shared/widgets/komanda_confirmation_categories_view.dart';

class KomandaOrderFlowPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserRole;
  final String restaurantId;

  const KomandaOrderFlowPage({
    super.key,
    this.currentUserId = '',
    this.currentUserName = '',
    this.currentUserRole = '',
    this.restaurantId = '',
  });
  @override State<KomandaOrderFlowPage> createState() => _KomandaOrderFlowPageState();
}

class _KomandaOrderFlowPageState extends State<KomandaOrderFlowPage> {
  int step = 0;
  bool _awaitingCreatedOrder = false;
  final Set<String> _ordersBeforeSave = {};
  String _selectedTable = '';
  bool _joinTables = false;
  final Set<String> _joinedTables = <String>{};
  String _selectedWaiterId = '';
  String search = '';
  String category = 'Seleccionados';
  bool selectedOnly = false;
  bool _showProductFilters = true;
  bool _showTableAndWaiter = true;
  final customerNameController = TextEditingController();
  final kitchenNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final deliveryAddressController = TextEditingController();
  final generalNotesController = TextEditingController();
  KomandaOrderType? orderType;
  bool isUrgent = false;
  int plateNumber = 1;
  double deliveryFee = 0;
  final ScrollController _flowScrollController = ScrollController();

  @override
  void dispose() {
    customerNameController.dispose();
    kitchenNameController.dispose();
    customerPhoneController.dispose();
    deliveryAddressController.dispose();
    generalNotesController.dispose();
    _flowScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KomandaBloc, KomandaState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (_awaitingCreatedOrder && state.status == KomandaStatus.ready &&
            step == 2 && state.cart.isEmpty) {
          _awaitingCreatedOrder = false;
          final newOrders = state.orders.where((o) => !_ordersBeforeSave.contains(o.id)).toList();
          if (newOrders.length == 1) {
            _showPostOrderPayment(newOrders.single);
          } else {
            // No abrir cobro para un pedido que no se pueda identificar con seguridad.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pedido guardado. Puedes cobrarlo desde Cobros.'),
            ));
            _returnToDashboard();
          }
          return;
        }

        if (state.status == KomandaStatus.failure &&
            state.errorMessage != null) {
          _awaitingCreatedOrder = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No se pudo guardar el pedido. ${state.errorMessage}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) => KomandaPhoneFrame(
        child: Column(children: [
          KomandaHeader(title: step == 1 || step == 2 ? 'Nuevo pedido · ${orderType == KomandaOrderType.delivery ? 'Domicilio' : orderType == KomandaOrderType.takeaway ? 'Para llevar' : 'Para aquí'}' : 'Nuevo pedido', subtitle: 'Paso ${step + 1} de 3'),
          _Progress(current: step),
          Expanded(child: Stack(children: [
            Positioned.fill(child: SingleChildScrollView(controller: _flowScrollController, padding: const EdgeInsets.only(bottom: 90), child: _body(context, state))),
            if (step >= 0 && step <= 2)
              Positioned(right: 16, bottom: 16, child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (step == 1) FloatingActionButton.small(
                    heroTag: 'komanda-selected-filter',
                    tooltip: selectedOnly ? 'Ver catálogo' : 'Ver seleccionados',
                    onPressed: () => setState(() {
                      selectedOnly = !selectedOnly;
                      if (selectedOnly) search = '';
                    }),
                    child: Icon(selectedOnly ? Icons.grid_view_rounded : Icons.shopping_bag_outlined),
                  ),
                  if (step == 1) const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'komanda-cart-up',
                    tooltip: 'Ir arriba',
                    onPressed: () {
                      if (_flowScrollController.hasClients) {
                        _flowScrollController.animateTo(0, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
                      }
                    },
                    child: const Icon(Icons.keyboard_double_arrow_up_rounded),
                  ),
                  if (true) ...[
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'komanda-cart-jump',
                      tooltip: 'Ir abajo',
                      onPressed: () {
                        if (_flowScrollController.hasClients) {
                          _flowScrollController.animateTo(_flowScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
                        }
                      },
                      child: const Icon(Icons.keyboard_double_arrow_down_rounded),
                    ),
                  ],
                ],
              )),

          ])),
        ]),
      ),
    );
  }

  void _returnToDashboard() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, RouteNames.komandaDashboard, (route) => false);
  }

  Future<void> _showPostOrderPayment(KomandaOrder order) async {
    if (!mounted) return;
    final payNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [
          Icon(Icons.check_circle_rounded, color: KomandaTheme.primary),
          SizedBox(width: 10),
          Expanded(child: Text('¡Pedido registrado!')),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.displayReference, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(komandaMoney(order.total), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: KomandaTheme.primary)),
          const SizedBox(height: 12),
          const Text('El pedido se envió a impresión. ¿Deseas cobrarlo ahora o dejarlo pendiente?'),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cobrar después')),
          FilledButton.icon(onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.point_of_sale_rounded), label: const Text('Cobrar ahora')),
        ],
      ),
    );
    if (!mounted) return;
    if (payNow == true) {
      await showKomandaPaymentDialog(context: context, order: order);
    }
    _returnToDashboard();
  }

  Widget _body(BuildContext context, KomandaState state) {
    switch (step) {
      case 0: return _tableStep(context, state);
      case 1: return _productsStep(context, state);
      case 2: return _confirmationStep(context, state);
      default: return _confirmationStep(context, state);
    }
  }

  Widget _tableStep(BuildContext context, KomandaState state) {
    final isDelivery = orderType == KomandaOrderType.delivery;
    final canContinue = orderType != null;

    return Column(children: [
      KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('¿Dónde se entregará el pedido?', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
        const SizedBox(height: 5),
        const Text('Selecciona el tipo de servicio para continuar.', style: TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;
          final cards = [
            _OrderTypeCard(selected: orderType == KomandaOrderType.dineIn, icon: Icons.restaurant_outlined, title: 'Para aquí', subtitle: 'En mesa · Restaurante', onTap: () => setState(() { orderType = KomandaOrderType.dineIn; search = ''; category = ''; step = 1; })),
            _OrderTypeCard(selected: orderType == KomandaOrderType.takeaway, icon: Icons.shopping_bag_outlined, title: 'Para llevar', subtitle: 'Recoger el pedido', onTap: () => setState(() { orderType = KomandaOrderType.takeaway; search = ''; category = ''; step = 1; })),
            _OrderTypeCard(selected: orderType == KomandaOrderType.delivery, icon: Icons.delivery_dining_outlined, title: 'Domicilio', subtitle: 'Entrega a domicilio', onTap: () => setState(() { orderType = KomandaOrderType.delivery; search = ''; category = ''; step = 1; })),
          ];
          if (narrow) return Column(children: [for (final card in cards) ...[card, const SizedBox(height: 10)]]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: cards[i])]]);
        }),
        const SizedBox(height: 18),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF3EDFF), borderRadius: BorderRadius.circular(16)), child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: KomandaTheme.purple), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isDelivery ? 'Entrega a domicilio' : orderType == KomandaOrderType.takeaway ? 'Pedido para llevar' : 'Servicio en restaurante', style: const TextStyle(color: KomandaTheme.purple, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(isDelivery ? 'Los datos del cliente y dirección se capturan al final.' : 'Los pedidos se identifican por ficha y se organizan por platos para cocina.', style: const TextStyle(color: KomandaTheme.softText)),
          ])),
        ])),
      ])),
    ]);
  }

  Widget _productsStep(BuildContext context, KomandaState state) {
    final categories = {...state.products.map((p) => p.category)}.where((v) => v.trim().isNotEmpty).toList()..sort();
    final isRestaurantThree = widget.restaurantId.trim() == '3';
    final defaultCategory = isRestaurantThree
        ? categories.where((value) => value.trim().toLowerCase() == 'tacos').firstOrNull
        : null;
    final activeCategory = categories.contains(category)
        ? category
        : (defaultCategory ?? (categories.isEmpty ? '' : categories.first));
    final selectedProductIds = state.cart.values.map((item) => item.productId).toSet();
    final products = state.products.where((p) {
      final byCategory = p.category == activeCategory;
      final bySearch = search.isEmpty ||
          p.name.toLowerCase().contains(search.toLowerCase()) ||
          p.category.toLowerCase().contains(search.toLowerCase());
      return p.available && byCategory && bySearch;
    }).toList();
    // Restaurante 3 / Tacos: barbacoa sin queso, otras carnes y al final
    // todas las variantes con queso. No cambia el orden de otros restaurantes.
    if (isRestaurantThree && activeCategory.trim().toLowerCase() == 'tacos') {
      int tacoGroup(String name) {
        final value = name.toLowerCase();
        if (value.contains('queso') || value.contains('quesadilla')) return 2;
        if (value.contains('barbacoa')) return 0;
        return 1;
      }
      products.sort((a, b) {
        final group = tacoGroup(a.name).compareTo(tacoGroup(b.name));
        if (group != 0) return group;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    return Column(children: [
      if (!selectedOnly) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Align(alignment: Alignment.centerRight, child: TextButton.icon(
          onPressed: () => setState(() => _showProductFilters = !_showProductFilters),
          icon: Icon(_showProductFilters ? Icons.expand_less_rounded : Icons.expand_more_rounded),
          label: Text(_showProductFilters ? 'Ocultar búsqueda y categorías' : 'Mostrar búsqueda y categorías'),
        )),
      ),
      if (!selectedOnly && _showProductFilters) KomandaSearchField(
        hintText: 'Buscar producto...',
        onChanged: (value) => setState(() => search = value),
      ),
      if (!selectedOnly && _showProductFilters) Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map((value) => _LargeCategoryFilter(
                    text: value,
                    selected: activeCategory == value,
                    onTap: () => setState(() => category = value),
                  ))
              .toList(),
        ),
      ),
      if (!selectedOnly && orderType != null)
        KomandaCard(
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 570;
            final title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${state.ticketConfig.plateLabel.trim().isEmpty ? 'Plato' : state.ticketConfig.plateLabel} actual', style: const TextStyle(fontWeight: FontWeight.w900)),
              if (!compact) const Text('Todo lo que agregues quedará separado en este grupo para cocina.', style: TextStyle(fontSize: 11, color: KomandaTheme.softText, fontWeight: FontWeight.w700)),
            ]);
            final controls = Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Plato anterior', constraints: const BoxConstraints(minWidth: 36, minHeight: 40), padding: EdgeInsets.zero,
                onPressed: plateNumber <= 1 ? null : () => setState(() => plateNumber--), icon: const Icon(Icons.remove_circle_outline)),
              Flexible(child: Text('${state.ticketConfig.plateLabel.trim().isEmpty ? 'Plato' : state.ticketConfig.plateLabel} $plateNumber', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 20 : 27, fontWeight: FontWeight.w900))),
              IconButton(tooltip: 'Plato siguiente', constraints: const BoxConstraints(minWidth: 36, minHeight: 40), padding: EdgeInsets.zero,
                onPressed: () => setState(() => plateNumber++), icon: const Icon(Icons.add_circle_outline)),
            ]);
            return compact ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.dining_outlined, color: KomandaTheme.purple), const SizedBox(width: 8), Expanded(child: title),
              IconButton(
                tooltip: 'Cambiar nombre de Plato / Servicio',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final controller = TextEditingController(text: state.ticketConfig.plateLabel);
                  final name = await showDialog<String>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Nombre del grupo'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Plato, Servicio, Orden...',
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  );
                  controller.dispose();
                  if (!mounted || name == null || name.isEmpty) return;
                  context.read<KomandaBloc>().add(
                    KomandaTicketConfigSaved(state.ticketConfig.copyWith(plateLabel: name)),
                  );
                },
              ),
              ]),
              const SizedBox(height: 8),
              Center(child: controls),
            ]) : Row(children: [const Icon(Icons.dining_outlined, color: KomandaTheme.purple), const SizedBox(width: 12), Expanded(child: title),
              IconButton(
                tooltip: 'Cambiar nombre de Plato / Servicio',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final controller = TextEditingController(text: state.ticketConfig.plateLabel);
                  final name = await showDialog<String>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Nombre del grupo'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Plato, Servicio, Orden...',
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  );
                  controller.dispose();
                  if (!mounted || name == null || name.isEmpty) return;
                  context.read<KomandaBloc>().add(
                    KomandaTicketConfigSaved(state.ticketConfig.copyWith(plateLabel: name)),
                  );
                },
              ),
              controls,
            ]);
          }),
        ),
      if (!selectedOnly) KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(activeCategory.isEmpty ? 'Productos' : activeCategory, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
          KChip(text: '${state.cart.values.fold<int>(0, (s, i) => s + i.quantity)} en carrito', icon: Icons.shopping_cart_outlined),
        ]),
        if (products.isEmpty) Padding(padding: const EdgeInsets.all(28), child: Center(child: Text('No se encontraron productos en esta categoría.', textAlign: TextAlign.center)))
        else LayoutBuilder(
          builder: (context, constraints) {
            // Celular conserva la lista cómoda de una columna. En tablet/web
            // mostramos 3 o 4 productos por fila para agilizar la captura.
            final width = constraints.maxWidth;
            final columns = width >= 980 ? 4 : width >= 650 ? 3 : 1;
            const gap = 10.0;
            final itemWidth = columns == 1
                ? width
                : (width - (gap * (columns - 1))) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: products.map((p) {
                final productEntries = state.cart.entries
                    .where((entry) => entry.value.productId == p.id &&
                        (orderType == null || entry.value.specifications.contains('Plato $plateNumber')))
                    .toList();
                final qty = productEntries.fold<int>(
                  0,
                  (sum, entry) => sum + entry.value.quantity,
                );
                final lastCartKey = productEntries.isEmpty ? null : productEntries.last.key;
                final view = ui.KomandaProduct(
                  name: p.printName,
                  note: p.category,
                  quantity: qty,
                  price: p.price,
                  image: '',
                );
                return SizedBox(
                  width: itemWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: qty > 0 ? KomandaTheme.purple : const Color(0xFFE7E7EF),
                        width: qty > 0 ? 2.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _quickAddProduct(context, state, p),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ProductTile(product: view, image: true, controls: false, verticalLayout: true),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ])),
      if (selectedOnly && state.cart.isEmpty)
        const KomandaCard(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aún no hay productos seleccionados. Usa el botón de catálogo para agregarlos.')))),
      if (state.cart.isNotEmpty) KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 22),
          const Text('Detalle seleccionado', style: TextStyle(fontWeight: FontWeight.w900, color: KomandaTheme.purple)),
          const SizedBox(height: 8),
          ..._cartEntriesByPlate(state.cart).expand((group) => [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: InkWell(
                    onTap: () => setState(() => plateNumber = _plateNumber(group.$1)),
                    child: Row(children: [
                      Checkbox(value: plateNumber == _plateNumber(group.$1), onChanged: (_) => setState(() => plateNumber = _plateNumber(group.$1))),
                      Text(group.$1, style: const TextStyle(fontWeight: FontWeight.w900, color: KomandaTheme.purple, fontSize: 25)),
                      if (plateNumber == _plateNumber(group.$1)) const Flexible(child: Text(' · Seleccionado', style: TextStyle(color: KomandaTheme.green, fontWeight: FontWeight.w800))),
                    ]),
                  ),
                ),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  for (final category in ['consome', 'refresco'])
                    OutlinedButton.icon(
                      onPressed: () {
                        final matches = state.products.where((p) => p.category.toLowerCase().contains(category) && p.available).toList();
                        if (matches.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No hay productos de $category disponibles')));
                          return;
                        }
                        setState(() => plateNumber = _plateNumber(group.$1));
                        if (matches.length == 1) {
                          _quickAddProduct(context, state, matches.first);
                        } else {
                          showModalBottomSheet<void>(context: context, builder: (sheetContext) => SafeArea(child: ListView(shrinkWrap: true, children: [
                            for (final product in matches) ListTile(title: Text(product.name), onTap: () {
                              Navigator.pop(sheetContext);
                              _quickAddProduct(context, state, product);
                            }),
                          ])));
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(category == 'consome' ? 'Consomé' : 'Refresco'),
                    ),
                ]),
                ...group.$2.map((entry) => _SelectedCartItemCard(
                      cartKey: entry.key,
                      item: entry.value,
                      onRemove: () => context.read<KomandaBloc>().add(
                            KomandaProductRemoved(entry.key),
                          ),
                      onAdd: () => context.read<KomandaBloc>().add(
                            KomandaCartItemRepeated(entry.key),
                          ),
                      onConfigure: () => _configureCartItem(context, state, entry.key, entry.value),
                      hasConfiguration: state.products.any((p) => p.id == entry.value.productId && p.hasOptions),
                      onNote: () => _editCartItemNote(context, entry.key, entry.value),
                      onDelete: () => context.read<KomandaBloc>().add(KomandaCartLineDeleted(entry.key)),
                    )),
              ]),
      ])),
      const SizedBox(height: 20),
    _totals(state.cartTotal),
      _navigation(onBack: () => setState(() => step = 0), onNext: state.cart.isNotEmpty ? () => setState(() => step = 2) : null),
    ]);
  }

  Widget _summaryStep(BuildContext context, KomandaState state) => Column(children: [
    KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Resumen del pedido', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Ficha #${_nextFicha(state)}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: KomandaTheme.purple),
        ),
      ),
      const Divider(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Productos (${state.cart.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), InkWell(onTap: () => setState(() => step = 1), child: const Text('✎ Editar', style: TextStyle(color: KomandaTheme.purple, fontWeight: FontWeight.w900)))]),
      KomandaOrderSectionsView(
        items: state.cart.values.toList(),
        showPrice: true,
      ),
    ])),
    _totals(state.cartTotal),
    if (orderType == KomandaOrderType.takeaway || orderType == KomandaOrderType.delivery)
      KomandaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicaciones para llevar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KomandaTheme.text),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escribe aquí qué salsas, ingredientes o cosas quieren que se manden aparte. Esta nota es del pedido completo.',
              style: TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: generalNotesController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota general para llevar',
                hintText: 'Ej. mandar salsa verde aparte, cebolla, limones...',
                prefixIcon: Icon(Icons.takeout_dining_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    KomandaCard(child: SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: isUrgent, onChanged: (value) => setState(() => isUrgent = value), secondary: Icon(Icons.priority_high_rounded, color: isUrgent ? KomandaTheme.red : KomandaTheme.softText), title: const Text('¿Es un pedido urgente?', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(isUrgent ? 'Se marcará como prioritario para cocina.' : 'Se atenderá con prioridad normal.'))),
    _navigation(onBack: () => setState(() => step = 1), onNext: () => setState(() => step = 3)),
  ]);

  KomandaWaiter? _sessionWaiter(KomandaState state) {
    final userId = widget.currentUserId.trim();
    if (userId.isEmpty) return null;
    for (final waiter in state.activeWaiters) {
      if (waiter.userId.trim() == userId) return waiter;
    }
    return null;
  }

  Widget _confirmationStep(BuildContext context, KomandaState state) {
    final skipTableAndWaiter = widget.restaurantId.trim() == '2' || orderType != KomandaOrderType.dineIn;
    final sessionWaiter = _sessionWaiter(state);
    final waiterIsAutomatic = sessionWaiter != null;
    if (waiterIsAutomatic && _selectedWaiterId != sessionWaiter.id) {
      _selectedWaiterId = sessionWaiter.id;
    }

    final tableCard = !skipTableAndWaiter && orderType == KomandaOrderType.dineIn
        ? KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.table_restaurant_rounded, color: KomandaTheme.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Seleccionar mesa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 5),
            const Text('Elige una mesa disponible para este pedido.', style: TextStyle(color: KomandaTheme.softText)),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Juntar mesas', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(_joinTables ? 'Seleccionadas: ${_joinedTables.length}' : 'Activa para seleccionar varias mesas en una sola cuenta.'),
              value: _joinTables,
              onChanged: (value) => setState(() {
                _joinTables = value;
                _joinedTables.clear();
                if (value && _selectedTable.isNotEmpty) _joinedTables.add(_selectedTable);
              }),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const KomandaTablesAdminPage()));
                  if (context.mounted) {
                    context.read<KomandaBloc>().add(const KomandaRefreshed(showLoading: false));
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear mesa'),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 540 ? 4 : constraints.maxWidth >= 340 ? 3 : 2;
              final tables = state.tables.where((table) => table.active).toList()
                ..sort((a, b) => _naturalTableCompare(a.name, b.name));
              if (tables.isEmpty) return const Text('No hay mesas configuradas.');
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tables.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 1.45,
                ),
                itemBuilder: (context, index) {
                  final table = tables[index];
                  final occupied = state.openOrderForTable(table.name) != null;
                  final selected = _joinTables ? _joinedTables.contains(table.name) : _selectedTable == table.name;
                  return Material(
                    color: occupied ? const Color(0xFFF5F6F8) : selected ? const Color(0xFFFFF1E5) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: occupied ? null : () {
                        setState(() {
                          if (_joinTables) {
                            if (!_joinedTables.add(table.name)) _joinedTables.remove(table.name);
                            _selectedTable = _joinedTables.isEmpty ? '' : _joinedTables.first;
                          } else {
                            _selectedTable = table.name;
                          }
                        });
                        context.read<KomandaBloc>().add(KomandaTableSelected(_selectedTable));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: selected ? KomandaTheme.primary : KomandaTheme.border, width: selected ? 2 : 1),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(occupied ? Icons.event_busy_outlined : selected ? Icons.check_circle_rounded : Icons.table_restaurant_outlined,
                            color: occupied ? KomandaTheme.softText : KomandaTheme.primary, size: 24),
                          const SizedBox(height: 5),
                          Text(table.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(occupied ? 'Ocupada' : selected ? 'Seleccionada' : 'Disponible',
                            style: TextStyle(fontSize: 11, color: occupied ? KomandaTheme.softText : KomandaTheme.primary)),
                        ]),
                      ),
                    ),
                  );
                },
              );
            }),
          ]))
        : null;
    final waiterCard = skipTableAndWaiter || waiterIsAutomatic
        ? null
        : KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.badge_outlined, color: KomandaTheme.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Asignar mesero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 5),
            const Text('Selecciona quién atenderá este pedido.', style: TextStyle(color: KomandaTheme.softText)),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const KomandaWaitersPage()));
                if (context.mounted) context.read<KomandaBloc>().add(const KomandaRefreshed(showLoading: false));
              },
              icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Crear mesero'),
            )),
            const SizedBox(height: 12),
            if (state.activeWaiters.isEmpty)
              const Text('No hay meseros activos configurados.')
            else
              ...state.activeWaiters.map((w) {
                final selected = _selectedWaiterId == w.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    color: selected ? const Color(0xFFFFF1E5) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedWaiterId = w.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: selected ? KomandaTheme.primary : KomandaTheme.border, width: selected ? 2 : 1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: selected ? const Color(0xFFFFDCC0) : const Color(0xFFF1F3F6),
                            child: Icon(Icons.person_outline_rounded, color: selected ? KomandaTheme.primary : KomandaTheme.softText),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                          Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: selected ? KomandaTheme.primary : KomandaTheme.softText),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
          ]));

    return Column(children: [
    if (!skipTableAndWaiter) ...[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _showTableAndWaiter = !_showTableAndWaiter),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Row(children: [
              const Icon(Icons.table_restaurant_outlined, color: KomandaTheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(waiterIsAutomatic ? 'Mesa disponible' : 'Mesa y mesero', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
              Text(_showTableAndWaiter ? 'Ocultar' : 'Mostrar', style: const TextStyle(color: KomandaTheme.primary, fontWeight: FontWeight.w700)),
              Icon(_showTableAndWaiter ? Icons.expand_less : Icons.expand_more),
            ]),
          ),
        ),
      ),
      if (_showTableAndWaiter) LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        if (!wide) {
          return Column(children: [if (tableCard != null) tableCard, if (waiterCard != null) waiterCard]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tableCard != null) Expanded(child: tableCard),
            if (tableCard != null && waiterCard != null) const SizedBox(width: 12),
            if (waiterCard != null) Expanded(child: waiterCard),
          ],
        );
      }),
    ],
    KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.receipt_long_rounded, color: KomandaTheme.primary, size: 26)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Confirma tu pedido', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
          SizedBox(height: 3),
          Text('Revisa los detalles antes de enviarlo a cocina', style: TextStyle(fontSize: 12, color: KomandaTheme.softText)),
        ])),
      ]),
      const SizedBox(height: 18),
      Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: const Color(0xFFFFF4EB), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.storefront_outlined, size: 19, color: KomandaTheme.primary),
          const SizedBox(width: 8),
          Text(orderType == KomandaOrderType.delivery ? 'A domicilio' : orderType == KomandaOrderType.takeaway ? 'Para llevar' : 'Para aquí', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(12)), child: Text('Ficha #${_nextFicha(state)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: KomandaTheme.text))),
        IconButton(tooltip: 'Cambiar tipo de venta', onPressed: () => setState(() => step = 0), icon: const Icon(Icons.swap_horiz_rounded, color: KomandaTheme.primary)),
      ]),
    ])),
    KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.restaurant_menu_rounded, color: KomandaTheme.primary, size: 23),
        const SizedBox(width: 9),
        const Expanded(child: Text('Productos del pedido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KomandaTheme.text))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(20)), child: Text('${state.cart.values.fold<int>(0, (sum, item) => sum + item.quantity)} artículos', style: const TextStyle(color: KomandaTheme.primary, fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 12),
      KomandaConfirmationCategoriesView(items: state.cart.values.toList()),
    ])),
    if (orderType == KomandaOrderType.takeaway) KomandaCard(child: TextField(onTap: () => kitchenNameController.selection = TextSelection(baseOffset: 0, extentOffset: kitchenNameController.text.length), controller: kitchenNameController, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: 'NOMBRE CLIENTE (opcional)', helperText: 'Solo se imprime en el ticket de cocina', prefixIcon: const Icon(Icons.restaurant), suffixIcon: KomandaTouchKeyboard.button(context, kitchenNameController, uppercase: true), border: const OutlineInputBorder()))),
    if (orderType == KomandaOrderType.delivery)
      KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Datos de entrega', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
        const SizedBox(height: 5),
        const Text('Captura los datos del domicilio antes de confirmar.', style: TextStyle(color: KomandaTheme.softText)),
        const SizedBox(height: 14),
        TextField(onTap: () => customerNameController.selection = TextSelection(baseOffset: 0, extentOffset: customerNameController.text.length), controller: customerNameController, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: 'Nombre del cliente (opcional)', prefixIcon: const Icon(Icons.person_outline), suffixIcon: KomandaTouchKeyboard.button(context, customerNameController), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(onTap: () => customerPhoneController.selection = TextSelection(baseOffset: 0, extentOffset: customerPhoneController.text.length), controller: customerPhoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Teléfono (opcional)', prefixIcon: const Icon(Icons.phone_outlined), suffixIcon: KomandaTouchKeyboard.button(context, customerPhoneController, numeric: true), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(onTap: () => deliveryAddressController.selection = TextSelection(baseOffset: 0, extentOffset: deliveryAddressController.text.length), controller: deliveryAddressController, textCapitalization: TextCapitalization.sentences, minLines: 2, maxLines: 3, decoration: InputDecoration(labelText: 'Dirección (opcional)', prefixIcon: const Icon(Icons.location_on_outlined), suffixIcon: KomandaTouchKeyboard.button(context, deliveryAddressController), border: const OutlineInputBorder())),
        const SizedBox(height: 14),
        const Text('Costo de envío', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [0.0, 5.0, 10.0, 15.0, 20.0].map((value) => ChoiceChip(label: Text(value == 0 ? 'Gratis' : '\$${value.toStringAsFixed(0)}'), selected: deliveryFee == value, onSelected: (_) => setState(() => deliveryFee = value))).toList()),
      ])),
    _totals(state.cartTotal),
    if (isUrgent) KomandaCard(child: const ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: Color(0xFFFFE7E7), child: Icon(Icons.priority_high_rounded, color: KomandaTheme.red)), title: Text('Pedido urgente', style: TextStyle(fontWeight: FontWeight.w900, color: KomandaTheme.red)), subtitle: Text('Este pedido se marcará como prioritario para cocina.'))),
    Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final backButton = OutlinedButton(
            onPressed: () => setState(() => step = 1),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Atrás'),
          );
          final confirmButton = FilledButton.icon(
            onPressed: state.status == KomandaStatus.saving ||
                (!skipTableAndWaiter && orderType == KomandaOrderType.dineIn &&
                 (_selectedTable.isEmpty ||
                  (_joinTables && _joinedTables.length < 2) ||
                  (_joinTables && _joinedTables.join(', ').length > 80) ||
                  (_joinTables && _joinedTables.any((name) => !state.tables.any((t) => t.active && t.name == name && state.openOrderForTable(t.name) == null))) ||
                  !state.tables.any((t) => t.active && t.name == _selectedTable && state.openOrderForTable(t.name) == null)))
                ? null : () {
              _ordersBeforeSave..clear()..addAll(state.orders.map((o) => o.id));
              _awaitingCreatedOrder = true;
              context.read<KomandaBloc>().add(KomandaOrderCreated(
              joinedTables: _joinTables ? _joinedTables.toList() : const [],
              notes: (orderType == KomandaOrderType.takeaway || orderType == KomandaOrderType.delivery)
                  ? generalNotesController.text.trim()
                  : '',
              orderType: orderType ?? KomandaOrderType.dineIn,
              customerName: customerNameController.text.trim(),
              kitchenName: kitchenNameController.text.trim().toUpperCase(),
              customerPhone: customerPhoneController.text.trim(),
              deliveryAddress: deliveryAddressController.text.trim(),
              deliveryFee: orderType == KomandaOrderType.delivery ? deliveryFee : 0,
              isUrgent: isUrgent,
              waiter: skipTableAndWaiter
                  ? null
                  : sessionWaiter ?? (state.activeWaiters.where((w) => w.id == _selectedWaiterId).isEmpty
                      ? null
                      : state.activeWaiters.firstWhere((w) => w.id == _selectedWaiterId)),
            ));
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: state.status == KomandaStatus.saving
                ? const Text('Actualizando...', style: TextStyle(fontWeight: FontWeight.w800))
                : const Icon(Icons.check_circle_outline),
            label: Text(
              state.status == KomandaStatus.saving ? 'Confirmando...' : 'Confirmar pedido',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [confirmButton, const SizedBox(height: 10), backButton],
            );
          }
          return Row(
            children: [
              Expanded(child: backButton),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: confirmButton),
            ],
          );
        },
      ),
    ),
  ]);
  }


  void _quickAddProduct(BuildContext context, KomandaState state, KomandaProduct product) {
    // Un toque agrega una línea nueva, incluso si ya existe el mismo producto.
    // Las opciones de cada línea se editan exclusivamente desde el carrito.
    // Paquetes y carne por peso conservan sus flujos necesarios de composición/peso.
    if (product.isPackage || _isMeatByWeight(product)) {
      _addConfiguredProduct(context, state, product);
      return;
    }
    context.read<KomandaBloc>().add(
      KomandaConfiguredProductAdded(
        product: product,
        specifications: ['Plato $plateNumber'],
        quantity: 1,
        separateLine: true,
      ),
    );
  }


  Future<void> _configureCartItem(BuildContext context, KomandaState state, String key, KomandaOrderItem item) async {
    KomandaProduct? product;
    for (final candidate in state.products) {
      if (candidate.id == item.productId) { product = candidate; break; }
    }
    if (product == null || !product.hasOptions) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este producto no tiene configuraciones disponibles.')));
      return;
    }
    final existing = item.specifications.where((v) => !v.startsWith('Plato ') && !v.toLowerCase().startsWith('nota:')).toList();
    final updated = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductOptionsSheet(product: product!, availableProducts: state.products,
        initialSpecifications: existing),
    );
    if (!context.mounted || updated == null) return;
    final plateAndNotes = item.specifications.where((v) => v.startsWith('Plato ') || v.toLowerCase().startsWith('nota:')).toList();
    context.read<KomandaBloc>().add(KomandaCartItemSpecificationsChanged(cartKey: key, specifications: [...plateAndNotes, ...updated]));
  }

  Future<void> _editCartItemNote(BuildContext context, String key, KomandaOrderItem item) async {
    final existing = item.specifications.where((v) => v.toLowerCase().startsWith('nota:')).toList();
    final controller = TextEditingController(text: existing.isEmpty ? '' : existing.last.substring(5).trim());
    final note = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Notas · ${item.name}'),
      content: TextField(controller: controller, autofocus: true, maxLines: 3,
        decoration: const InputDecoration(hintText: 'Indicaciones para cocina', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Volver')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Guardar'))],
    ));
    controller.dispose();
    if (!context.mounted || note == null) return;
    context.read<KomandaBloc>().add(KomandaCartItemNoteChanged(cartKey: key, note: note));
  }
  void _removeAllProductEntries(BuildContext context, List<String> keys) {
    final bloc = context.read<KomandaBloc>();
    for (final key in keys) {
      bloc.add(KomandaCartLineDeleted(key));
    }
  }

  Future<void> _addConfiguredProduct(
    BuildContext context,
    KomandaState state,
    KomandaProduct product,
  ) async {
    // Desde el catálogo siempre se configura una línea nueva. Para aumentar
    // una configuración existente se utiliza exclusivamente el botón + del carrito.
    final specifications = <String>[];
    var productForCart = product;

    if (orderType != null) {
      specifications.add('Plato $plateNumber');
    }

    if (product.isPackage) {
      final packageSelections = await showModalBottomSheet<List<_PackageSelectionItem>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PackageCompositionSheet(
          product: product,
          allProducts: state.products,
        ),
      );
      if (!context.mounted || packageSelections == null) return;

      for (final packageItem in packageSelections) {
        final childProduct = _findProductForPackageSelection(
          state.products,
          packageItem,
        );
        if (childProduct == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No se pudo cargar ${packageItem.productName} para configurar el paquete.',
              ),
            ),
          );
          return;
        }

        specifications.add('${packageItem.slotLabel}: ${childProduct.printName}');

        if (childProduct.hasOptions) {
          final childSpecs = await showModalBottomSheet<List<String>>(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => _ProductOptionsSheet(
              product: childProduct,
              availableProducts: state.products,
              initialSpecifications: const [],
              titleOverride: '${packageItem.slotLabel} · ${childProduct.printName}',
              subtitleOverride: 'Configura este producto del paquete. Esta selección es independiente de los demás productos.',
            ),
          );
          if (!context.mounted || childSpecs == null) return;
          for (final childSpec in childSpecs) {
            specifications.add('${packageItem.slotLabel} · $childSpec');
          }
        }
      }
    }

    if (!product.isPackage && _isMeatByWeight(product)) {
      final selection = await _selectMeatAmount(
        context,
        pricePerKg: product.price,
      );
      if (!context.mounted || selection == null) return;
      specifications.add('Peso: ${_formatKilograms(selection.kilograms)} kg');
      if (!_isChicharron(product)) {
        specifications.add('Importe carne: ${komandaMoney(selection.amount)}');
      }
      productForCart = product.copyWith(price: selection.amount);
    }

    if (!product.isPackage && product.hasOptions) {
      final result = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _ProductOptionsSheet(
          product: product,
          availableProducts: state.products,
          initialSpecifications: const [],
          subtitleOverride: 'Selecciona las opciones configuradas para este producto.',
        ),
      );
      if (!context.mounted || result == null) return;
      specifications.addAll(result);
      productForCart = productForCart.copyWith(
        price: productForCart.price + _selectedExtrasPrice(product, result),
      );
    }

    final addConfig = await _showAddConfiguration(
      context,
      productName: product.name,
      specifications: specifications,
    );
    if (!context.mounted || addConfig == null) return;

    final finalSpecifications = [...specifications];
    if (addConfig.note.trim().isNotEmpty) {
      finalSpecifications.add('Nota: ${addConfig.note.trim()}');
    }

    context.read<KomandaBloc>().add(
          KomandaConfiguredProductAdded(
            product: productForCart,
            specifications: finalSpecifications,
            quantity: addConfig.quantity,
            separateLine: true,
          ),
        );
  }

  KomandaProduct? _findProductForPackageSelection(
    List<KomandaProduct> products,
    _PackageSelectionItem selection,
  ) {
    final id = selection.productId.trim();
    if (id.isNotEmpty) {
      for (final product in products) {
        if (product.id == id) return product;
      }
    }

    final name = selection.productName.trim().toLowerCase();
    for (final product in products) {
      if (product.name.trim().toLowerCase() == name ||
          product.printName.trim().toLowerCase() == name) {
        return product;
      }
    }
    return null;
  }

  Future<_MeatAmountSelection?> _selectMeatAmount(
    BuildContext context, {
    required double pricePerKg,
  }) {
    final controller = TextEditingController();
    var mode = _MeatAmountMode.kilograms;

    return showModalBottomSheet<_MeatAmountSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final raw = controller.text.trim().replaceAll(',', '.');
          final value = double.tryParse(raw) ?? 0.0;
          final kilograms = mode == _MeatAmountMode.kilograms
              ? value
              : (pricePerKg > 0 ? value / pricePerKg : 0.0);
          final amount = mode == _MeatAmountMode.money
              ? value
              : value * pricePerKg;
          final isValid = value > 0 && pricePerKg > 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cantidad de carne',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KomandaTheme.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Precio por kilo: ${komandaMoney(pricePerKg)}',
                      style: const TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<_MeatAmountMode>(
                      segments: const [
                        ButtonSegment(value: _MeatAmountMode.kilograms, icon: Icon(Icons.scale_outlined), label: Text('Kilogramos')),
                        ButtonSegment(value: _MeatAmountMode.money, icon: Icon(Icons.attach_money_rounded), label: Text('Cantidad en \$')),
                      ],
                      selected: {mode},
                      onSelectionChanged: (values) {
                        setSheetState(() {
                          mode = values.first;
                          controller.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: mode == _MeatAmountMode.kilograms ? 'Kilogramos' : 'Cantidad de dinero',
                        hintText: mode == _MeatAmountMode.kilograms ? 'Ej. 0.350, 0.750, 1.250' : 'Ej. 50, 100, 250',
                        prefixIcon: Icon(mode == _MeatAmountMode.kilograms ? Icons.scale_outlined : Icons.attach_money_rounded),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: KomandaTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Conversión', style: TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            isValid
                                ? '${_formatKilograms(kilograms)} kg = ${komandaMoney(amount)}'
                                : 'Ingresa una cantidad mayor a 0',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KomandaTheme.purple),
                          ),
                          if (isValid) ...[
                            const SizedBox(height: 4),
                            Text(
                              mode == _MeatAmountMode.kilograms
                                  ? '${_formatKilograms(kilograms)} kg × ${komandaMoney(pricePerKg)} por kg'
                                  : '${komandaMoney(amount)} ÷ ${komandaMoney(pricePerKg)} por kg',
                              style: const TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isValid
                            ? () => Navigator.pop(sheetContext, _MeatAmountSelection(kilograms: kilograms, amount: amount))
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Usar esta cantidad'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }


  bool _isChicharron(KomandaProduct product) {
    final category = product.category.trim().toLowerCase();
    final name = product.name.trim().toLowerCase();
    return category.contains('chicharr') || name.contains('chicharr');
  }

  bool _isMeatByWeight(KomandaProduct product) {
    final category = product.category.trim().toLowerCase();
    final name = product.name.trim().toLowerCase();
    return category == 'carnes por kilo' ||
        (category.contains('carne') && category.contains('kilo')) ||
        name.contains('kilo');
  }

  String _formatKilograms(double value) {
    var formatted = value.toStringAsFixed(3);

    while (formatted.contains('.') && formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    return formatted;
  }

  Future<_AddProductConfiguration?> _showAddConfiguration(
    BuildContext context, {
    required String productName,
    required List<String> specifications,
  }) {
    final noteController = TextEditingController();
    var quantity = 1;
    return showModalBottomSheet<_AddProductConfiguration>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text(
                    'Antes de agregar: indica cuántas veces quieres esta misma configuración y agrega una nota solo para este producto.',
                    style: TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700),
                  ),
                  if (specifications.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: specifications.map((value) => Chip(label: Text(value))).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Text('Repetir esta configuración', style: TextStyle(fontWeight: FontWeight.w900))),
                      IconButton(
                        onPressed: quantity <= 1 ? null : () => setSheetState(() => quantity--),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 42),
                        alignment: Alignment.center,
                        child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                      IconButton(
                        onPressed: () => setSheetState(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nota de este producto',
                      hintText: 'Ej. sin cebolla, bien dorado...',
                      prefixIcon: Icon(Icons.sticky_note_2_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        _AddProductConfiguration(quantity: quantity, note: noteController.text),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(quantity == 1 ? 'Agregar al carrito' : 'Agregar $quantity iguales'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<(String, List<MapEntry<String, KomandaOrderItem>>)> _cartEntriesByPlate(
    Map<String, KomandaOrderItem> cart,
  ) {
    final groups = <String, List<MapEntry<String, KomandaOrderItem>>>{};
    for (final entry in cart.entries) {
      final label = _plateLabel(entry.value);
      groups.putIfAbsent(label, () => []).add(entry);
    }
    final values = groups.entries.toList();
    values.sort((a, b) => _plateNumber(a.key).compareTo(_plateNumber(b.key)));
    return values.map((e) => (e.key, e.value)).toList();
  }

  List<Widget> _summaryItemsByPlate(Map<String, KomandaOrderItem> cart) {
    return _cartEntriesByPlate(cart).expand((group) => <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(group.$1, style: const TextStyle(fontWeight: FontWeight.w900, color: KomandaTheme.purple)),
      ),
      ...group.$2.map((entry) => KomandaItemDetailView(item: entry.value, showPrice: true)),
    ]).toList();
  }

  String _plateLabel(KomandaOrderItem item) {
    for (final specification in item.specifications) {
      final value = specification.trim();
      if (value.toLowerCase().startsWith('plato ')) return value;
    }
    return 'Sin plato';
  }

  int _plateNumber(String label) {
    final match = RegExp(r'(\d+)').firstMatch(label);
    return int.tryParse(match?.group(1) ?? '') ?? 9999;
  }

  double _selectedExtrasPrice(KomandaProduct product, List<String> specifications) {
    var total = 0.0;
    for (final specification in specifications) {
      final separator = specification.indexOf(':');
      if (separator <= 0) continue;
      final groupName = specification.substring(0, separator).trim();
      final label = specification.substring(separator + 1).trim();
      for (final group in product.selectableOptionGroups) {
        if (group.name.trim() != groupName) continue;
        for (final option in group.optionDetails) {
          if (option.label.trim() == label) total += option.extraPrice;
        }
      }
    }
    return total;
  }

  String _nextFicha(KomandaState state) =>
      komandaNextDailyFolio(state.orders, DateTime.now());

  Widget _totals(double productsTotal) {
    final fee = orderType == KomandaOrderType.delivery ? deliveryFee : 0.0;
    final total = productsTotal + fee;
    return KomandaCard(child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Productos', style: TextStyle(color: KomandaTheme.softText)), Text(komandaMoney(productsTotal))]),
      if (fee > 0) ...[
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Envío a domicilio', style: TextStyle(color: KomandaTheme.softText)), Text(komandaMoney(fee))]),
      ],
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(komandaMoney(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KomandaTheme.purple))]),
    ]));
  }

  Widget _navigation({required VoidCallback onBack, required VoidCallback? onNext}) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
    child: LayoutBuilder(builder: (context, constraints) {
      final back = OutlinedButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Atrás'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))));
      final next = FilledButton.icon(onPressed: onNext, iconAlignment: IconAlignment.end, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Continuar'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))));
      if (constraints.maxWidth < 380) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [next, const SizedBox(height: 10), back]);
      return Row(children: [Expanded(child: back), const SizedBox(width: 12), Expanded(flex: 2, child: next)]);
    }),
  );

}




class _SelectedCartItemCard extends StatelessWidget {
  final String cartKey;
  final KomandaOrderItem item;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onConfigure;
  final bool hasConfiguration;
  final VoidCallback onNote;
  final VoidCallback onDelete;

  const _SelectedCartItemCard({
    required this.cartKey,
    required this.item,
    required this.onRemove,
    required this.onAdd,
    required this.onConfigure,
    required this.hasConfiguration,
    required this.onNote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KomandaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KomandaItemDetailView(item: item, showPrice: true),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (hasConfiguration) OutlinedButton.icon(onPressed: onConfigure, icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Configuraciones')),
            IconButton(onPressed: onNote, tooltip: 'Notas', iconSize: 29, icon: const Icon(Icons.edit_note_rounded)),
            IconButton(onPressed: onDelete, tooltip: 'Eliminar todo', iconSize: 29, color: KomandaTheme.red, icon: const Icon(Icons.delete_outline_rounded)),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFFFF2E8), borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(tooltip: 'Quitar uno', onPressed: onRemove, icon: const Icon(Icons.remove_circle_outline_rounded, color: KomandaTheme.purple)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900))),
                IconButton(tooltip: 'Agregar uno', onPressed: onAdd, icon: const Icon(Icons.add_circle_rounded, color: KomandaTheme.purple)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeCategoryFilter extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _LargeCategoryFilter({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? KomandaTheme.purple.withOpacity(.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? KomandaTheme.purple : KomandaTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: selected ? KomandaTheme.purple : KomandaTheme.text,
            ),
          ),
        ),
      );
}

enum _MeatAmountMode { kilograms, money }

class _MeatAmountSelection {
  final double kilograms;
  final double amount;

  const _MeatAmountSelection({required this.kilograms, required this.amount});
}

class _AddProductConfiguration {
  final int quantity;
  final String note;
  const _AddProductConfiguration({required this.quantity, required this.note});
}

class _OrderTypeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OrderTypeCard({required this.selected, required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(button: true, selected: selected, label: title, child: InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(duration: const Duration(milliseconds: 180), constraints: const BoxConstraints(minHeight: 172), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: selected ? const Color(0xFFFFF3E8) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? KomandaTheme.purple : KomandaTheme.border, width: selected ? 2 : 1), boxShadow: const [BoxShadow(color: Color(0x0A172238), blurRadius: 12, offset: Offset(0, 5))]),
      child: Stack(children: [
        if (selected) const Positioned(top: 0, right: 0, child: Icon(Icons.check_circle_rounded, color: KomandaTheme.purple, size: 26)),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 27, backgroundColor: selected ? const Color(0xFFFFE4CE) : const Color(0xFFF0F2F8), child: Icon(icon, color: selected ? KomandaTheme.purple : KomandaTheme.softText, size: 28)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: KomandaTheme.softText)),
        ])),
      ]),
    ),
  ));
}

class _PackageSelectionItem {
  final String productId;
  final String productName;
  final String slotLabel;

  const _PackageSelectionItem({
    required this.productId,
    required this.productName,
    required this.slotLabel,
  });
}

class _PackageCompositionSheet extends StatefulWidget {
  final KomandaProduct product;
  final List<KomandaProduct> allProducts;

  const _PackageCompositionSheet({
    required this.product,
    required this.allProducts,
  });

  @override
  State<_PackageCompositionSheet> createState() =>
      _PackageCompositionSheetState();
}

class _PackageCompositionSheetState extends State<_PackageCompositionSheet> {
  late final Map<String, Map<String, int>> counts;

  @override
  void initState() {
    super.initState();
    counts = {
      for (final group in widget.product.packageGroups)
        group.id: <String, int>{},
    };

    // Si un grupo tiene una única opción y cantidad fija, se llena solo.
    // Ejemplo: "Torta" -> solo existe el producto Tortas -> 1 requerida.
    for (final group in widget.product.packageGroups) {
      final exactQty = group.maxSelections != null &&
              group.maxSelections == group.minSelections
          ? group.maxSelections!
          : 0;
      if (group.optionDetails.length == 1 && exactQty > 0) {
        final option = group.optionDetails.first;
        counts[group.id]![_optionKey(option)] = exactQty;
      }
    }
  }

  String _optionKey(KomandaProductOption option) {
    if (option.linkedProductId.trim().isNotEmpty) {
      return 'id:${option.linkedProductId.trim()}';
    }
    return 'name:${option.label.trim().toLowerCase()}';
  }

  KomandaProduct? _linkedProduct(KomandaProductOption option) {
    if (option.linkedProductId.trim().isNotEmpty) {
      for (final p in widget.allProducts) {
        if (p.id == option.linkedProductId.trim()) return p;
      }
    }

    for (final p in widget.allProducts) {
      if (p.name.trim().toLowerCase() == option.label.trim().toLowerCase()) {
        return p;
      }
    }
    return null;
  }

  int totalFor(KomandaProductOptionGroup group) =>
      counts[group.id]!.values.fold(0, (a, b) => a + b);

  bool get valid => widget.product.packageGroups.every((group) {
        final count = totalFor(group);
        final min = group.minSelections > 0
            ? group.minSelections
            : (group.required ? 1 : 0);
        final max = group.maxSelections;
        return count >= min && (max == null || count <= max);
      });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F7FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: KomandaTheme.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 10, 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1E5),
                    child: Icon(Icons.inventory_2_outlined,
                        color: KomandaTheme.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: KomandaTheme.text,
                          ),
                        ),
                        const Text(
                          'Elige qué va dentro del paquete. Después te pediré los complementos de cada producto.',
                          style: TextStyle(
                            color: KomandaTheme.softText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                children: widget.product.packageGroups.map((group) {
                  final min = group.minSelections > 0
                      ? group.minSelections
                      : (group.required ? 1 : 0);
                  final max = group.maxSelections;
                  final current = totalFor(group);
                  final requirement = max != null && max == min
                      ? 'Debes elegir $max'
                      : max == null
                          ? 'Mínimo $min'
                          : 'Elige de $min a $max';

                  return KomandaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: KomandaTheme.text,
                                ),
                              ),
                            ),
                            Text(
                              '$current / ${max ?? min}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: KomandaTheme.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          requirement,
                          style: const TextStyle(
                            fontSize: 11,
                            color: KomandaTheme.softText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...group.optionDetails.map((option) {
                          final key = _optionKey(option);
                          final amount = counts[group.id]![key] ?? 0;
                          final linked = _linkedProduct(option);
                          final groups = linked?.selectableOptionGroups ?? const <KomandaProductOptionGroup>[];
                          final hasOptions = groups.isNotEmpty;
                          final canAdd = max == null || current < max;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: KomandaTheme.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: hasOptions
                                    ? KomandaTheme.purple.withOpacity(.10)
                                    : const Color(0xFFF3F3F7),
                                child: Icon(
                                  hasOptions
                                      ? Icons.tune_rounded
                                      : Icons.restaurant_menu_rounded,
                                  color: hasOptions
                                      ? KomandaTheme.purple
                                      : KomandaTheme.softText,
                                ),
                              ),
                              title: Text(
                                option.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: KomandaTheme.text,
                                ),
                              ),
                              subtitle: hasOptions
                                  ? Text(
                                      'Después seleccionarás: ${groups.map((g) => g.name).join(' · ')}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: KomandaTheme.purple,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : const Text(
                                      'No requiere complementos adicionales',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: KomandaTheme.softText,
                                      ),
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: amount <= 0
                                        ? null
                                        : () => setState(() {
                                              counts[group.id]![key] = amount - 1;
                                            }),
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text(
                                    '$amount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: !canAdd
                                        ? null
                                        : () => setState(() {
                                              counts[group.id]![key] = amount + 1;
                                            }),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: !valid
                      ? null
                      : () {
                          final result = <_PackageSelectionItem>[];
                          for (final group in widget.product.packageGroups) {
                            final totalInGroup = totalFor(group);
                            var position = 0;
                            for (final option in group.optionDetails) {
                              final amount = counts[group.id]![
                                      _optionKey(option)] ??
                                  0;
                              for (var i = 0; i < amount; i++) {
                                position++;
                                result.add(
                                  _PackageSelectionItem(
                                    productId: option.linkedProductId,
                                    productName: option.label,
                                    slotLabel: totalInGroup > 1
                                        ? '${group.name} $position'
                                        : group.name,
                                  ),
                                );
                              }
                            }
                          }
                          Navigator.pop(context, result);
                        },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'Continuar a seleccionar ingredientes',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductOptionsSheet extends StatefulWidget {
  final KomandaProduct product;
  final List<KomandaProduct> availableProducts;
  final List<String> initialSpecifications;
  final String? titleOverride;
  final String? subtitleOverride;

  const _ProductOptionsSheet({
    required this.product,
    this.availableProducts = const [],
    this.initialSpecifications = const [],
    this.titleOverride,
    this.subtitleOverride,
  });

  @override
  State<_ProductOptionsSheet> createState() => _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends State<_ProductOptionsSheet> {
  late final Map<String, Set<String>> selected;

  bool _allowsMultiple(KomandaProductOptionGroup group) => group.multiple;

  List<KomandaProductOption> _availableOptions(KomandaProductOptionGroup group) {
    if (group.optionDetails.isEmpty || widget.availableProducts.isEmpty) return group.optionDetails;
    return group.optionDetails.where((option) {
      final linkedId = option.linkedProductId.trim();
      if (linkedId.isNotEmpty) {
        final matches = widget.availableProducts.where((p) => p.id == linkedId);
        if (matches.isNotEmpty) return matches.first.available;
      }

      final optionName = option.label.trim().toLowerCase();
      final byName = widget.availableProducts.where(
        (p) => p.name.trim().toLowerCase() == optionName,
      );
      if (byName.isNotEmpty) return byName.first.available;

      return true;
    }).toList();
  }

  List<String> _availableLabels(KomandaProductOptionGroup group) {
    if (group.optionDetails.isEmpty) return group.options;
    return _availableOptions(group).map((option) => option.label).toList();
  }

  @override
  void initState() {
    super.initState();
    selected = {};
    for (final group in widget.product.selectableOptionGroups) {
      final matches = widget.initialSpecifications
          .map((value) {
            final prefix = '${group.name}: ';
            return value.startsWith(prefix) ? value.substring(prefix.length) : value;
          })
          .where((value) => _availableLabels(group).contains(value))
          .toSet();
      final availableLabels = _availableLabels(group);
      selected[group.id] = matches;
    }
  }

  bool get isValid => widget.product.selectableOptionGroups.every((group) {
        final availableLabels = _availableLabels(group);
        // Sin opciones disponibles, el usuario tambien puede continuar.
        final values = (selected[group.id] ?? const <String>{}).where(availableLabels.contains).toSet();
        final max = group.maxSelections;
        // Permitir continuar sin seleccionar complementos; si se eligen,
        // se siguen respetando los limites maximos del grupo.
        // El minimo no bloquea la opcion de omitir complementos.

        if (max != null && max > 0 && values.length > max) return false;
        return true;
      });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F7FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: KomandaTheme.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 10, 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1E5),
                    child: Icon(Icons.tune, color: KomandaTheme.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titleOverride ?? widget.product.printName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: KomandaTheme.text,
                          ),
                        ),
                        Text(
                          widget.subtitleOverride ??
                              'Selecciona cómo debe prepararse este producto.',
                          style: const TextStyle(
                            color: KomandaTheme.softText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  children: widget.product.selectableOptionGroups.map((group) {
                    final values = selected[group.id] ?? <String>{};
                    return KomandaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: KomandaTheme.text,
                                  ),
                                ),
                              ),
                              Text(
                                _allowsMultiple(group) ? 'Puedes elegir varias' : 'Elige una',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: KomandaTheme.softText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableLabels(group).map((option) {
                              final active = values.contains(option);
                              return FilterChip(
                                selected: active,
                                label: Text(option),
                                onSelected: (_) {
                                  setState(() {
                                    final groupValues = selected[group.id] ?? <String>{};
                                    if (_allowsMultiple(group)) {
                                      if (active) {
                                        groupValues.remove(option);
                                      } else {
                                        final max = group.maxSelections;
                                        if (max == null || max <= 0 || groupValues.length < max) {
                                          groupValues.add(option);
                                        }
                                      }
                                    } else {
                                      groupValues
                                        ..clear()
                                        ..add(option);
                                    }
                                    selected[group.id] = groupValues;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isValid
                      ? () {
                          final specifications = <String>[];
                          for (final group in widget.product.selectableOptionGroups) {
                            for (final value in selected[group.id] ?? const <String>{}) {
                              specifications.add('${group.name}: $value');
                            }
                          }
                          Navigator.pop(context, specifications);
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Agregar con estas opciones'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableOrderCard extends StatelessWidget {
  final KomandaOrder order;
  final bool active;
  final VoidCallback onTap;

  const _TableOrderCard({
    required this.order,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? KomandaTheme.purple : KomandaTheme.border,
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: active
                    ? KomandaTheme.purple.withOpacity(.10)
                    : const Color(0xFFF3F3F7),
                child: Icon(
                  active ? Icons.receipt_long : Icons.history,
                  color: active ? KomandaTheme.purple : KomandaTheme.softText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${order.shortFolio}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: KomandaTheme.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.totalItems} productos · ${order.status.label}',
                      style: const TextStyle(
                        color: KomandaTheme.softText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${order.createdAt.day.toString().padLeft(2, '0')}/'
                      '${order.createdAt.month.toString().padLeft(2, '0')}/'
                      '${order.createdAt.year} · '
                      '${order.createdAt.hour.toString().padLeft(2, '0')}:'
                      '${order.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: KomandaTheme.softText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    komandaMoney(order.total),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: active ? KomandaTheme.green : KomandaTheme.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: KomandaTheme.softText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTableOrderCard extends StatelessWidget {
  final String table;
  const _EmptyTableOrderCard({required this.table});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KomandaTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_seat_outlined,
            size: 34,
            color: KomandaTheme.green,
          ),
          const SizedBox(height: 8),
          Text(
            '$table está disponible',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: KomandaTheme.text,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'No se creará ningún pedido al tocar la mesa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: KomandaTheme.softText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int current;
  const _Progress({required this.current});
  @override
  Widget build(BuildContext context) {
    const labels = ['Tipo de pedido', 'Productos', 'Confirmar'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= current;
          return Expanded(
            child: Column(children: [
              Row(children: [
                if (index > 0) Expanded(child: Container(height: 2, color: index <= current ? KomandaTheme.purple : KomandaTheme.border)),
                Container(
                  width: 27, height: 27, alignment: Alignment.center,
                  decoration: BoxDecoration(color: active ? KomandaTheme.purple : Colors.white, shape: BoxShape.circle, border: Border.all(color: active ? KomandaTheme.purple : KomandaTheme.border)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () { final page = context.findAncestorStateOfType<_KomandaOrderFlowPageState>(); if (page != null && index <= page.step) page.setState(() => page.step = index); },
                    child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? Colors.white : KomandaTheme.softText))),
                  ),
                ),
                if (index < labels.length - 1) Expanded(child: Container(height: 2, color: index < current ? KomandaTheme.purple : KomandaTheme.border)),
              ]),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: index == current ? KomandaTheme.purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(labels[index], textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: index == current ? Colors.white : KomandaTheme.softText)),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

extension _KomandaFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

// Orden natural: Mesa 1, Mesa 2, ... Mesa 10.
int _naturalTableCompare(String a, String b) {
  final pattern = RegExp(r'(\d+)');
  final ma = pattern.firstMatch(a);
  final mb = pattern.firstMatch(b);
  if (ma != null && mb != null) {
    final prefix = a.substring(0, ma.start).toLowerCase().compareTo(b.substring(0, mb.start).toLowerCase());
    if (prefix != 0) return prefix;
    final number = int.parse(ma.group(0)!).compareTo(int.parse(mb.group(0)!));
    if (number != 0) return number;
  }
  return a.toLowerCase().compareTo(b.toLowerCase());
}
