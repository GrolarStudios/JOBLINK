import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/komanda_theme.dart';
import '../../../core/utils/komanda_money.dart';
import '../../../core/utils/komanda_order_sections.dart';
import '../../../domain/entities/komanda_order.dart';
import '../../../domain/entities/komanda_product.dart';
import '../../../domain/entities/komanda_complement.dart';
import '../../../data/datasources/komanda_remote_datasource.dart';
import '../../bloc/komanda_bloc.dart';
import '../../bloc/komanda_event.dart';
import '../../bloc/komanda_state.dart';
import '../../widgets/komanda_widgets.dart';
import '../../shared/widgets/komanda_item_detail_view.dart';
import '../../pages/komanda_detail_page.dart';

class KomandaChefOrdersPage extends StatelessWidget {
  final KomandaRemoteDataSource remote;
  const KomandaChefOrdersPage({super.key, required this.remote});

  @override
  Widget build(BuildContext context) {
    return KomandaPhoneFrame(child: Column(children:[
      const KomandaHeader(title:'Cocina',menu:true,bell:false),
      Expanded(child: FutureBuilder<List<Map<String,dynamic>>>(
        future: remote.getKitchenStations(),
        builder:(context,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting) return const Center(child:CircularProgressIndicator());
          final rows=snapshot.data??const <Map<String,dynamic>>[];
          if(rows.isEmpty) return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No hay puestos de cocina configurados. Configúralos en la base de datos.')));
          return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,20),children:[
            const Text('Puestos de cocina',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:KomandaTheme.text)),
            const SizedBox(height:12),
            ...rows.where((r)=>r['active']==true||r['active']==1||r['active']=='1').map((r){
              final station=_KitchenStationConfig.fromMap(r);
              return Padding(padding:const EdgeInsets.only(bottom:12),child:_KitchenAccessCard(icon:Icons.soup_kitchen_rounded,title:station.name,subtitle:'Vista configurable por categorías y productos',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_KitchenStationPage(title:station.name,station:station,remote:remote)))));
            }),
          ]);
        },
      )),
    ]));
  }
}

class _KitchenStationConfig {
  final String id,name,slug; final Set<String> categoryNames,productIds;
  const _KitchenStationConfig({required this.id,required this.name,required this.slug,this.categoryNames=const {},this.productIds=const {}});
  factory _KitchenStationConfig.fromMap(Map<String,dynamic> m)=>_KitchenStationConfig(id:'${m['id']??''}',name:'${m['name']??'Cocina'}',slug:'${m['slug']??''}',categoryNames:((m['categoryNames'] as List?)??const[]).map((e)=>'$e'.trim().toLowerCase()).toSet(),productIds:((m['productIds'] as List?)??const[]).map((e)=>'$e').toSet());
}

class _KitchenStationPage extends StatefulWidget {
  final String title;
  final _KitchenStationConfig station;
  final KomandaRemoteDataSource remote;

  const _KitchenStationPage({required this.title, required this.station, required this.remote});

  @override
  State<_KitchenStationPage> createState() => _KitchenStationPageState();
}

class _KitchenStationPageState extends State<_KitchenStationPage> {
  String statusFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final active = state.orders
            .where((order) =>
        order.status == KomandaOrderStatus.pending ||
            order.status == KomandaOrderStatus.preparing)
            .where((order) => _itemsForStation(order, widget.station).isNotEmpty)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final orders = active.where((order) {
          final items = _itemsForStation(order, widget.station);
          final byStatus = statusFilter == 'Todos' || order.status.label == statusFilter;
          return byStatus;
        }).toList();

        return KomandaPhoneFrame(
          child: Column(
            children: [
              KomandaHeader(title: widget.title, bell: false),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showSoldOutProducts(context, state.products),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.remove_shopping_cart_outlined),
                    label: const Text('Agotar'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['Todos', 'Pendiente', 'Preparando']
                      .map(
                        (value) => _LargeKitchenFilter(
                      text: value,
                      selected: statusFilter == value,
                      onTap: () => setState(() => statusFilter = value),
                    ),
                  )
                      .toList(),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => context.read<KomandaBloc>().add(const KomandaRefreshed()),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 18),
                    children: [
                      KomandaCard(
                        child: Row(
                          children: [
                            _Metric(title: 'Activos', value: '${active.length}', color: KomandaTheme.purple),
                            _Metric(
                              title: 'Preparando',
                              value: '${active.where((o) => o.status == KomandaOrderStatus.preparing).length}',
                              color: KomandaTheme.orange,
                            ),
                            _Metric(
                              title: 'Pendientes',
                              value: '${active.where((o) => o.status == KomandaOrderStatus.pending).length}',
                              color: KomandaTheme.blue,
                            ),
                          ],
                        ),
                      ),
                      if (orders.isEmpty)
                        const KomandaCard(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No hay pedidos activos para este puesto.')),
                          ),
                        )
                      else
                        ...orders.map(
                              (order) => _KitchenOrderCard(
                            order: order,
                            items: _itemsForStation(order, widget.station),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSoldOutProducts(BuildContext context, List<KomandaProduct> products) async {
    List<KomandaComplement> complements = const [];
    List<Map<String, dynamic>> optionCatalogs = const [];
    try {
      final rows = await widget.remote.getComplements();
      complements = rows.map((r) => KomandaComplement(
        id: (r['id'] ?? '').toString(),
        type: (r['type'] ?? '').toString(),
        name: (r['name'] ?? '').toString(),
        extraPrice: (r['extraPrice'] as num? ?? 0).toDouble(),
        active: r['active'] == true || r['active'] == 1,
      )).toList();
    } catch (_) {
      complements = const [];
    }
    try {
      optionCatalogs = (await widget.remote.getOptionCatalogs())
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      optionCatalogs = const [];
    }

    if (!mounted) return;

    final stationProducts = products.where((product) => product.isPackage || _productAvailableInStation(product, widget.station)).toList();
    final categories = <String>{
      ...stationProducts.map((p) => p.category.trim()).where((e) => e.isNotEmpty),
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    String selectedFilter = 'Complementos';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final showComplements = selectedFilter == 'Complementos';
          final filteredProducts = stationProducts.where((product) {
            if (selectedFilter == 'Complementos') return false;
            return product.category.trim() == selectedFilter;
          }).toList()
            ..sort((a, b) {
              final byCategory = a.category.toLowerCase().compareTo(b.category.toLowerCase());
              if (byCategory != 0) return byCategory;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

          final filteredComplements = complements.where((item) {
            if (!showComplements) return false;
            return _complementAvailableInStation(item, widget.station);
          }).toList()
            ..sort((a, b) {
              final aMeat = a.type.trim().toLowerCase() == 'carne';
              final bMeat = b.type.trim().toLowerCase() == 'carne';
              if (aMeat != bMeat) return aMeat ? -1 : 1;
              final aExactCarne = a.name.trim().toLowerCase() == 'carne';
              final bExactCarne = b.name.trim().toLowerCase() == 'carne';
              if (aExactCarne != bExactCarne) return aExactCarne ? -1 : 1;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

          final catalogOnlyOptions = <Map<String, dynamic>>[];
          if (showComplements) {
            for (final catalog in optionCatalogs) {
              if (!(catalog['active'] == true || catalog['active'] == 1)) continue;
              final catalogName = (catalog['name'] ?? '').toString();
              final values = (catalog['values'] as List? ?? const []);
              for (final raw in values.whereType<Map>()) {
                final value = Map<String, dynamic>.from(raw);
                // Si está enlazada a un complemento o producto, se controla
                // desde esa fila para no mostrar duplicados. Aquí quedan
                // sabores/tamaños/opciones puramente configurables.
                if ((value['complementId'] ?? '').toString().trim().isNotEmpty) continue;
                if ((value['linkedProductId'] ?? '').toString().trim().isNotEmpty) continue;
                value['_catalogId'] = (catalog['id'] ?? '').toString();
                value['_catalogName'] = catalogName;
                catalogOnlyOptions.add(value);
              }
            }
            catalogOnlyOptions.sort((a, b) {
              final an = (a['label'] ?? '').toString().trim().toLowerCase();
              final bn = (b['label'] ?? '').toString().trim().toLowerCase();
              if (an == 'carne' && bn != 'carne') return -1;
              if (bn == 'carne' && an != 'carne') return 1;
              return an.compareTo(bn);
            });
          }

          final totalRows = filteredProducts.length + filteredComplements.length + catalogOnlyOptions.length;

          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * .88),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agotar · ${widget.title}',
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Primero se muestran los complementos. Dentro de Complementos aparecen primero las carnes y después los rellenos.',
                          style: TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: ['Complementos', ...categories].map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: selectedFilter == filter,
                            onSelected: (_) => setSheetState(() => selectedFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: totalRows == 0
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No se encontraron productos o complementos.',
                                style: TextStyle(fontWeight: FontWeight.w800, color: KomandaTheme.softText),
                              ),
                            ),
                          )
                        : ListView(
                            children: [
                              ...filteredProducts.map((product) {
                                final category = product.category.trim().isEmpty ? 'Sin categoría' : product.category.trim();
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: product.available
                                            ? KomandaTheme.green.withOpacity(.12)
                                            : KomandaTheme.red.withOpacity(.12),
                                        child: Icon(
                                          product.available ? Icons.check_rounded : Icons.remove_shopping_cart_outlined,
                                          color: product.available ? KomandaTheme.green : KomandaTheme.red,
                                        ),
                                      ),
                                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                      subtitle: Text(
                                        '$category · ${product.available ? 'Disponible' : 'Agotado'}',
                                        style: TextStyle(
                                          color: product.available ? KomandaTheme.softText : KomandaTheme.red,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      trailing: FilledButton.tonal(
                                        onPressed: () async {
                                          final newAvailable = !product.available;
                                          await widget.remote.setProductAvailability(product.id, newAvailable);
                                          setSheetState(() {
                                            final index = stationProducts.indexWhere((p) => p.id == product.id);
                                            if (index >= 0) stationProducts[index] = product.copyWith(available: newAvailable);
                                          });
                                          if (context.mounted) {
                                            context.read<KomandaBloc>().add(const KomandaRefreshed());
                                          }
                                        },
                                        child: Text(product.available ? 'Agotar' : 'Activar'),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              }),
                              if (filteredComplements.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
                                  child: Text(
                                    'COMPLEMENTOS',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: KomandaTheme.softText),
                                  ),
                                ),
                              ...filteredComplements.map((item) {
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: item.active
                                            ? KomandaTheme.green.withOpacity(.12)
                                            : KomandaTheme.red.withOpacity(.12),
                                        child: Icon(
                                          item.type.toLowerCase() == 'carne'
                                              ? Icons.restaurant_rounded
                                              : Icons.rice_bowl_outlined,
                                          color: item.active ? KomandaTheme.green : KomandaTheme.red,
                                        ),
                                      ),
                                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                      subtitle: Text(
                                        'Complemento · ${item.type}${item.extraPrice > 0 ? ' · +${komandaMoney(item.extraPrice)}' : ''} · ${item.active ? 'Disponible' : 'Agotado'}',
                                        style: TextStyle(
                                          color: item.active ? KomandaTheme.softText : KomandaTheme.red,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      trailing: FilledButton.tonal(
                                        onPressed: () async {
                                          final newActive = !item.active;
                                          await widget.remote.setComplementAvailability(item.id, newActive);
                                          setSheetState(() {
                                            final index = complements.indexWhere((c) => c.id == item.id);
                                            if (index >= 0) {
                                              complements[index] = KomandaComplement(
                                                id: item.id,
                                                type: item.type,
                                                name: item.name,
                                                extraPrice: item.extraPrice,
                                                active: newActive,
                                              );
                                            }
                                          });
                                          if (context.mounted) {
                                            context.read<KomandaBloc>().add(const KomandaRefreshed());
                                          }
                                        },
                                        child: Text(item.active ? 'Agotar' : 'Activar'),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              }),
                              if (catalogOnlyOptions.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
                                  child: Text(
                                    'OPCIONES CONFIGURABLES',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: KomandaTheme.softText),
                                  ),
                                ),
                              ...catalogOnlyOptions.map((value) {
                                final active = value['active'] == true || value['active'] == 1;
                                final label = (value['label'] ?? '').toString();
                                final catalogName = (value['_catalogName'] ?? 'Configuración').toString();
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: active
                                            ? KomandaTheme.green.withOpacity(.12)
                                            : KomandaTheme.red.withOpacity(.12),
                                        child: Icon(Icons.tune_rounded, color: active ? KomandaTheme.green : KomandaTheme.red),
                                      ),
                                      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
                                      subtitle: Text(
                                        '$catalogName · ${active ? 'Disponible' : 'Agotado'}',
                                        style: TextStyle(
                                          color: active ? KomandaTheme.softText : KomandaTheme.red,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      trailing: FilledButton.tonal(
                                        onPressed: () async {
                                          final newActive = !active;
                                          await widget.remote.setOptionCatalogValueAvailability(
                                            (value['id'] ?? '').toString(),
                                            newActive,
                                          );
                                          setSheetState(() {
                                            final valueId = (value['id'] ?? '').toString();
                                            for (final catalog in optionCatalogs) {
                                              final values = (catalog['values'] as List? ?? const []);
                                              for (final raw in values.whereType<Map>()) {
                                                if ((raw['id'] ?? '').toString() == valueId) {
                                                  raw['active'] = newActive;
                                                }
                                              }
                                            }
                                          });
                                          if (context.mounted) {
                                            context.read<KomandaBloc>().add(const KomandaRefreshed());
                                          }
                                        },
                                        child: Text(active ? 'Agotar' : 'Activar'),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              }),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}

class _KitchenOrderCard extends StatelessWidget {
  final KomandaOrder order;
  final List<KomandaOrderItem> items;

  const _KitchenOrderCard({required this.order, required this.items});

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<KomandaBloc>().state.status == KomandaStatus.saving;
    final color = order.status == KomandaOrderStatus.pending ? KomandaTheme.purple : KomandaTheme.orange;
    final groups = _itemsGroupedByPlate(items);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => KomandaDetailPage(order: order),
        ),
      ),
      child: KomandaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(.12),
                child: Icon(Icons.confirmation_number_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ficha ${order.shortFolio}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text(
                      '${items.fold<int>(0, (sum, item) => sum + item.quantity)} productos · ${order.orderType.label}',
                      style: const TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700),
                    ),
                    if (order.isDelivery && order.customerName.trim().isNotEmpty)
                      Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (order.isUrgent)
                      const Text('URGENTE', style: TextStyle(color: KomandaTheme.red, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              KChip(text: order.status.label, color: color),
            ],
          ),
          const Divider(height: 20),
          ...groups.expand(
                (group) => <Widget>[
              if (group.$1 != 'Productos')
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: KomandaTheme.purple.withOpacity(.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    group.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: KomandaTheme.purple,
                      fontSize: 18,
                    ),
                  ),
                ),
              ...group.$2.map((item) => KomandaItemDetailView(item: item)),
              const Divider(height: 18),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (order.status == KomandaOrderStatus.pending)
                FilledButton.icon(
                  onPressed: saving ? null : () => _change(context, KomandaOrderStatus.preparing),
                  icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.soup_kitchen_rounded),
                  label: Text(saving ? 'Actualizando...' : 'Preparar'),
                ),
              if (order.status == KomandaOrderStatus.preparing)
                FilledButton.icon(
                  onPressed: saving ? null : () => _change(context, KomandaOrderStatus.waiting),
                  icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(saving ? 'Actualizando...' : 'Preparado'),
                ),
              TextButton(
                onPressed: () => _change(context, KomandaOrderStatus.cancelled),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _change(BuildContext context, KomandaOrderStatus status) {
    context.read<KomandaBloc>().add(KomandaOrderStatusChanged(orderId: order.id, status: status));
  }
}

class _KitchenAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _KitchenAccessCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KomandaTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundColor: KomandaTheme.purple.withOpacity(.10), child: Icon(icon, size: 30, color: KomandaTheme.purple)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _LargeKitchenFilter extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _LargeKitchenFilter({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? KomandaTheme.purple.withOpacity(.12) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? KomandaTheme.purple : KomandaTheme.border, width: selected ? 2 : 1),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: selected ? KomandaTheme.purple : KomandaTheme.text)),
    ),
  );
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _Metric({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        Text(title, style: const TextStyle(fontSize: 11, color: KomandaTheme.softText, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

bool _isSharedMeatProduct(KomandaProduct product) {
  final name = product.name.trim().toLowerCase();
  final category = product.category.trim().toLowerCase();
  if (category.contains('taco') || category.contains('torta') ||
      name.contains('taco') || name.contains('torta')) {
    return false;
  }
  const meatWords = [
    'lengua', 'maciza', 'buche', 'cachete', 'surtida', 'carnita',
    'chicharron', 'chicharrón', 'rinon', 'riñon', 'manita', 'kilo',
  ];
  return category.contains('carne') || meatWords.any(name.contains);
}

bool _productAvailableInStation(KomandaProduct product, _KitchenStationConfig station) {
  if (product.isPackage) return true;
  if (station.productIds.contains(product.id)) return true;
  final category=product.category.trim().toLowerCase();
  return station.categoryNames.contains(category);
}

bool _complementAvailableInStation(KomandaComplement item, _KitchenStationConfig station) {
  final value = '${item.type} ${item.name}'.trim().toLowerCase();
  // Carnes, salsas, rellenos y extras pueden compartirse entre estaciones.
  // Se usa el mismo registro remoto, por eso al agotarlo aquí también queda
  // agotado en la otra estación.
  return value.isNotEmpty;
}

List<KomandaOrderItem> _itemsForStation(KomandaOrder order, _KitchenStationConfig station) {
  return order.items.where((item) {
    if (station.productIds.contains(item.productId)) return true;
    return station.categoryNames.contains(item.category.trim().toLowerCase());
  }).toList();
}

List<(String, List<KomandaOrderItem>)> _itemsGroupedByPlate(List<KomandaOrderItem> items) {
  final groups = <String, List<KomandaOrderItem>>{};
  for (final item in items) {
    var plate = 'Productos';
    for (final specification in item.specifications) {
      if (specification.trim().toLowerCase().startsWith('plato ')) {
        plate = specification.trim();
        break;
      }
    }
    groups.putIfAbsent(plate, () => []).add(item);
  }
  final entries = groups.entries.toList()
    ..sort((a, b) => _plateNumber(a.key).compareTo(_plateNumber(b.key)));
  return entries.map((e) => (e.key, e.value)).toList();
}

int _plateNumber(String value) {
  final match = RegExp(r'(\d+)').firstMatch(value);
  return int.tryParse(match?.group(1) ?? '') ?? 9999;
}
