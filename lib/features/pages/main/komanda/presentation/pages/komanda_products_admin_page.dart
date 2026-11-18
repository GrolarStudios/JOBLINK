import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/komanda_money.dart';

import '../../data/datasources/komanda_remote_datasource.dart';
import '../../domain/entities/komanda_product.dart';
import '../../domain/entities/komanda_option_catalog.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';
import 'komanda_categories_page.dart';
import 'komanda_complements_admin_page.dart';
import 'komanda_option_catalogs_page.dart';


class _PackageSlotDraft {
  String label;
  final String category;
  final Set<String> allowedProductIds;

  _PackageSlotDraft({
    required this.label,
    required this.category,
    required Set<String> allowedProductIds,
  }) : allowedProductIds = Set<String>.from(allowedProductIds);
}

class KomandaProductsAdminPage extends StatefulWidget {
  final KomandaRemoteDataSource? remote;
  const KomandaProductsAdminPage({
    super.key,
    this.remote,
  });

  @override
  State<KomandaProductsAdminPage> createState() =>
      _KomandaProductsAdminPageState();
}

class _KomandaProductsAdminPageState
    extends State<KomandaProductsAdminPage> {
  String _search = '';
  String _category = 'Todos';
  bool _showFilters = false;
  bool _showActions = true;
  int _page=0; static const _pageSize=50;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<KomandaBloc>().add(
            const KomandaRefreshed(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final query = _search.trim().toLowerCase();

        final products = state.products.where((product) {
          final matchesCategory = _category == 'Todos' ||
              (_category == 'Paquetes' ? product.isPackage : product.category == _category);
          final matchesSearch = query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query);
          return matchesCategory && matchesSearch;
        }).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(
                  b.name.toLowerCase(),
                ),
          );

        final pages=(products.length/_pageSize).ceil().clamp(1,999999); if(_page>=pages)_page=pages-1; final pageProducts=products.skip(_page*_pageSize).take(_pageSize).toList();
        return KomandaPhoneFrame(
          child: Column(
            children: [
              const KomandaHeader(
                title: 'Administrar productos',
                subtitle: 'Productos, categorías y opciones',
              ),
              KomandaSearchField(
                hintText: 'Buscar producto o categoría',
                onChanged: (value) => setState(() => _search = value),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      icon: Icon(_showFilters ? Icons.filter_alt_off_outlined : Icons.filter_alt_outlined),
                      label: Text(_showFilters ? 'Ocultar filtros' : 'Filtros'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showActions = !_showActions),
                      icon: Icon(_showActions ? Icons.visibility_off_outlined : Icons.apps_rounded),
                      label: Text(_showActions ? 'Ocultar botones' : 'Botones'),
                    ),
                    if (_category != 'Todos')
                      Text(
                        'Mostrando: $_category',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
              ),
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _productFilterValues(state).map((value) => ChoiceChip(
                        label: Text(value),
                        selected: _category == value,
                        onSelected: (_) => setState(() => _category = value),
                      )).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              if (_showActions)
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 430;
                    Widget actionButton({
                      required IconData icon,
                      required String label,
                      required VoidCallback? onPressed,
                      required bool filled,
                    }) {
                      final child = FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );
                      return SizedBox(
                        height: 48,
                        child: filled
                            ? FilledButton.icon(
                                onPressed: onPressed,
                                icon: Icon(icon, size: 19),
                                label: child,
                              )
                            : OutlinedButton.icon(
                                onPressed: onPressed,
                                icon: Icon(icon, size: 19),
                                label: child,
                              ),
                      );
                    }

                    final buttons = <Widget>[
                      actionButton(
                        icon: Icons.add,
                        label: 'Producto',
                        filled: true,
                        onPressed: state.categories.isEmpty ? null : () => _openProductDialog(context, state),
                      ),
                      actionButton(
                        icon: Icons.inventory_2_outlined,
                        label: 'Paquete',
                        filled: false,
                        onPressed: state.categories.isEmpty || state.products.isEmpty
                            ? null
                            : () => _openPackageDialog(context, state),
                      ),
                      actionButton(
                        icon: Icons.category_outlined,
                        label: 'Categorías',
                        filled: false,
                        onPressed: () async {
                          await Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => const KomandaCategoriesPage()));
                          if (!context.mounted) return;
                          context.read<KomandaBloc>().add(const KomandaRefreshed());
                        },
                      ),
                      actionButton(
                        icon: Icons.tune_rounded,
                        label: 'Configuraciones',
                        filled: false,
                        onPressed: () async {
                          await Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => const KomandaOptionCatalogsPage()));
                          if (!context.mounted) return;
                          context.read<KomandaBloc>().add(const KomandaRefreshed());
                        },
                      ),
                      if (widget.remote != null)
                        actionButton(
                          icon: Icons.extension_rounded,
                          label: 'Complementos',
                          filled: false,
                          onPressed: () async {
                            await Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => KomandaComplementsAdminPage(remote: widget.remote!)));
                            if (context.mounted) context.read<KomandaBloc>().add(const KomandaRefreshed());
                          },
                        ),
                    ];

                    if (compact) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: buttons
                            .map((button) => SizedBox(
                                  width: (constraints.maxWidth - 8) / 2,
                                  child: button,
                                ))
                            .toList(),
                      );
                    }

                    return Row(
                      children: [
                        for (var i = 0; i < buttons.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: buttons[i]),
                        ],
                      ],
                    );
                  },
                ),
              ),
              if (state.categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: KomandaCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Primero registra al menos una categoría '
                            'para poder agregar productos.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: products.isEmpty
                    ? _buildEmptyState(context)
                    : _buildProductsList(
                        context,
                        state,
                        pageProducts,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _productFilterValues(KomandaState state) {
    final categories = state.categories.map((e) => e.name).toList()
      ..sort(_carneFirstCompare);
    return <String>['Todos', 'Paquetes', ...categories];
  }

  static int _carneFirstCompare(String a, String b) {
    int rank(String value) {
      final v = value.trim().toLowerCase();
      if (v == 'carne') return 0;
      if (v.startsWith('carne')) return 1;
      return 2;
    }
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.toLowerCase().compareTo(b.toLowerCase());
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _search.trim().isEmpty
                  ? 'No hay productos registrados.'
                  : 'No se encontraron productos.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    KomandaState state,
    List<KomandaProduct> products,
  ) {
    return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          24,
        ),
        itemCount: products.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final product = products[index];

          return KomandaCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: product.available
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.16),
                child: Icon(
                  product.available
                      ? Icons.restaurant_menu
                      : Icons.block,
                  color: product.available
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${product.category} · '
                  '${komandaMoney(product.price)}\n'
                  '${_optionGroupsLabel(product)}'
                  '${product.available ? '' : '\nNo disponible'}',
                ),
              ),
              trailing: Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    tooltip: 'Editar producto',
                    onPressed: () {
                      if (product.isPackage) {
                        _openPackageDialog(context, state, product);
                      } else {
                        _openProductDialog(
                          context,
                          state,
                          product,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar producto',
                    onPressed: () {
                      _confirmDeleteProduct(
                        context,
                        product,
                      );
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  String _optionGroupsLabel(
    KomandaProduct product,
  ) {
    if (product.isPackage) {
      return 'Paquete · ${product.packageItemLabels.join(' + ')}';
    }

    final count = product.selectableOptionGroups.length;

    if (count == 0) {
      return 'Producto simple';
    }

    if (count == 1) {
      return '1 grupo de opciones';
    }

    return '$count grupos de opciones';
  }

  Future<void> _openPackageDialog(
    BuildContext context,
    KomandaState state, [
    KomandaProduct? current,
  ]) async {
    final nameController = TextEditingController(text: current?.name ?? '');
    final priceController = TextEditingController(
      text: current == null ? '' : current.price.toStringAsFixed(2),
    );
    String pricingMode =
        current?.pricingMode == 'components' ? 'components' : 'fixed';

    final availableProducts = state.products
        .where((p) => !p.isPackage && p.available)
        .toList()
      ..sort((a, b) {
        final byCategory = a.category.toLowerCase().compareTo(b.category.toLowerCase());
        return byCategory != 0
            ? byCategory
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final packageCategories = <String>{
      ...availableProducts.map((p) => p.category.trim()).where((c) => c.isNotEmpty),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final slots = <_PackageSlotDraft>[];

    // Convierte tanto paquetes nuevos (1 grupo = 1 posición) como paquetes
    // anteriores (un grupo con cantidad > 1) al nuevo esquema por posiciones.
    if (current != null && current.isPackage) {
      for (final group in current.packageGroups) {
        final quantity = (group.maxSelections ?? group.minSelections) > 0
            ? (group.maxSelections ?? group.minSelections)
            : 1;
        final linkedIds = group.optionDetails
            .map((o) => o.linkedProductId.trim())
            .where((id) => id.isNotEmpty)
            .toSet();
        final linkedProducts = availableProducts
            .where((p) => linkedIds.contains(p.id))
            .toList();
        final inferredCategory = linkedProducts.isNotEmpty
            ? linkedProducts.first.category
            : packageCategories.isNotEmpty ? packageCategories.first : '';

        for (var i = 0; i < quantity; i++) {
          final baseName = quantity > 1
              ? '${_singularPackageLabel(group.name)} ${i + 1}'
              : group.name;
          slots.add(
            _PackageSlotDraft(
              label: baseName,
              category: inferredCategory,
              allowedProductIds: linkedIds.isEmpty
                  ? availableProducts
                      .where((p) => p.category == inferredCategory)
                      .map((p) => p.id)
                      .toSet()
                  : linkedIds,
            ),
          );
        }
      }
    }

    Future<void> addSlot(StateSetter setD) async {
      if (packageCategories.isEmpty) return;
      String category = packageCategories.first;
      final result = await showDialog<_PackageSlotDraft>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setSlot) {
            final productsForCategory = availableProducts
                .where((p) => p.category == category)
                .toList();
            return AlertDialog(
              title: const Text('Agregar posición al paquete'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Tipo / categoría del producto',
                        border: OutlineInputBorder(),
                      ),
                      items: packageCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSlot(() => category = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${productsForCategory.length} productos disponibles. '
                      'Después podrás decidir cuáles permite esta posición.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: productsForCategory.isEmpty
                      ? null
                      : () {
                          final sameCategoryCount = slots
                              .where((s) => s.category == category)
                              .length;
                          Navigator.pop(
                            dialogContext,
                            _PackageSlotDraft(
                              label: '${_singularPackageLabel(category)} ${sameCategoryCount + 1}',
                              category: category,
                              allowedProductIds:
                                  productsForCategory.map((p) => p.id).toSet(),
                            ),
                          );
                        },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        ),
      );
      if (result != null) setD(() => slots.add(result));
    }

    Future<void> editSlotProducts(
      StateSetter setD,
      _PackageSlotDraft slot,
    ) async {
      final productsForCategory = availableProducts
          .where((p) => p.category == slot.category)
          .toList();
      final selected = Set<String>.from(slot.allowedProductIds);
      final result = await showDialog<Set<String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setProducts) => AlertDialog(
            title: Text('Productos permitidos · ${slot.label}'),
            content: SizedBox(
              width: 540,
              height: 430,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slot.category,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setProducts(() {
                          selected
                            ..clear()
                            ..addAll(productsForCategory.map((p) => p.id));
                        }),
                        child: const Text('Todos'),
                      ),
                      TextButton(
                        onPressed: () => setProducts(selected.clear),
                        child: const Text('Ninguno'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: productsForCategory.length,
                      itemBuilder: (_, index) {
                        final product = productsForCategory[index];
                        final checked = selected.contains(product.id);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(product.printName),
                          subtitle: product.hasOptions
                              ? Text(
                                  'Configuraciones: ${product.selectableOptionGroups.map((g) => g.name).join(', ')}',
                                  style: const TextStyle(fontSize: 11),
                                )
                              : const Text('Producto simple', style: TextStyle(fontSize: 11)),
                          onChanged: (value) => setProducts(() {
                            if (value == true) {
                              selected.add(product.id);
                            } else {
                              selected.remove(product.id);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, selected),
                child: const Text('Guardar selección'),
              ),
            ],
          ),
        ),
      );
      if (result != null) {
        setD(() {
          slot.allowedProductIds
            ..clear()
            ..addAll(result);
        });
      }
    }

    final result = await showDialog<KomandaProduct>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setD) {
          final canSave = nameController.text.trim().isNotEmpty &&
              slots.isNotEmpty &&
              slots.every((slot) => slot.allowedProductIds.isNotEmpty) &&
              (pricingMode == 'components' ||
                  (double.tryParse(priceController.text.replaceAll(',', '.')) ?? -1) >= 0);

          return AlertDialog(
            title: Text(current == null ? 'Crear paquete' : 'Editar paquete'),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      onChanged: (_) => setD(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Nombre del paquete',
                        hintText: 'Ej. Paquete Torta + 2 Tacos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Posiciones del paquete',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: packageCategories.isEmpty ? null : () => addSlot(setD),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar posición'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cada posición se configura por separado. Por ejemplo: Torta 1, Taco 1 y Taco 2.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    if (slots.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 10),
                              Expanded(child: Text('Agrega al menos una posición al paquete.')),
                            ],
                          ),
                        ),
                      )
                    else
                      ...slots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final slot = entry.value;
                        final allowedProducts = availableProducts
                            .where((p) => slot.allowedProductIds.contains(p.id))
                            .toList();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      child: Text('${index + 1}'),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: slot.label,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre de la posición',
                                          isDense: true,
                                        ),
                                        onChanged: (value) => slot.label = value,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar posición',
                                      onPressed: () => setD(() => slots.removeAt(index)),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${slot.category} · ${allowedProducts.length} producto(s) permitido(s)',
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => editSlotProducts(setD, slot),
                                      icon: const Icon(Icons.tune_rounded, size: 18),
                                      label: const Text('Elegir productos'),
                                    ),
                                  ],
                                ),
                                if (allowedProducts.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: allowedProducts
                                        .map((p) => Chip(
                                              visualDensity: VisualDensity.compact,
                                              label: Text(p.printName),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'fixed',
                          label: Text('Precio fijo'),
                          icon: Icon(Icons.sell_outlined),
                        ),
                        ButtonSegment(
                          value: 'components',
                          label: Text('Suma componentes'),
                          icon: Icon(Icons.calculate_outlined),
                        ),
                      ],
                      selected: {pricingMode},
                      onSelectionChanged: (values) =>
                          setD(() => pricingMode = values.first),
                    ),
                    const SizedBox(height: 12),
                    if (pricingMode == 'fixed')
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setD(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Precio del paquete',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      const Text(
                        'El precio se calcula con los productos elegidos dentro del paquete.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: !canSave
                    ? null
                    : () {
                        final groups = <KomandaProductOptionGroup>[];
                        for (var i = 0; i < slots.length; i++) {
                          final slot = slots[i];
                          final label = slot.label.trim().isEmpty
                              ? 'Producto ${i + 1}'
                              : slot.label.trim();
                          final options = availableProducts
                              .where((p) => slot.allowedProductIds.contains(p.id))
                              .map(
                                (p) => KomandaProductOption(
                                  id: '',
                                  label: p.name,
                                  linkedProductId: p.id,
                                  linkedProduct: p,
                                ),
                              )
                              .toList();
                          groups.add(
                            KomandaProductOptionGroup(
                              id: '',
                              name: label,
                              options: options.map((e) => e.label).toList(),
                              optionDetails: options,
                              multiple: false,
                              required: true,
                              minSelections: 1,
                              maxSelections: 1,
                              allowRepeats: false,
                            ),
                          );
                        }

                        Navigator.pop(
                          dialogContext,
                          KomandaProduct(
                            id: current?.id ??
                                DateTime.now().microsecondsSinceEpoch.toString(),
                            name: nameController.text.trim(),
                            category: 'Paquetes',
                            price: pricingMode == 'fixed'
                                ? (double.tryParse(
                                        priceController.text.replaceAll(',', '.'),
                                      ) ??
                                    0)
                                : 0,
                            available: current?.available ?? true,
                            productKind: 'package',
                            pricingMode: pricingMode,
                            description: current?.description.isNotEmpty == true
                                ? current!.description
                                : 'Paquete configurable',
                            optionGroups: groups,
                          ),
                        );
                      },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar paquete'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    priceController.dispose();
    if (result != null && context.mounted) {
      context.read<KomandaBloc>().add(KomandaProductSaved(result));
    }
  }

  String _singularPackageLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Producto';
    if (trimmed.toLowerCase().endsWith('s') && trimmed.length > 1) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    KomandaProduct product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text(
            '¿Seguro que deseas eliminar "${product.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    context.read<KomandaBloc>().add(
          KomandaProductDeleted(product.id),
        );
  }

  Future<void> _openProductDialog(
    BuildContext context,
    KomandaState state, [
    KomandaProduct? product,
  ]) async {
    if (state.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero registra una categoría.',
          ),
        ),
      );
      return;
    }

    final categoryNames = state.categories
        .map((category) => category.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort(
        (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
      );

    if (categoryNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay categorías disponibles.',
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController(
      text: product?.name ?? '',
    );

    final priceController = TextEditingController(
      text: product == null
          ? ''
          : product.price.toStringAsFixed(2),
    );

    String selectedCategory;

    if (product != null &&
        categoryNames.contains(product.category)) {
      selectedCategory = product.category;
    } else {
      selectedCategory = categoryNames.first;
    }

    bool available = product?.available ?? true;

    final groups = <KomandaProductOptionGroup>[
      ...?product?.optionGroups,
    ];

    String? validationMessage;

    final savedProduct =
        await showDialog<KomandaProduct>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                product == null
                    ? 'Agregar producto'
                    : 'Editar producto',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Nombre del producto',
                          hintText:
                              'Ejemplo: Hamburguesa',
                          prefixIcon: Icon(
                            Icons.fastfood_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: Icon(
                            Icons.category_outlined,
                          ),
                        ),
                        items: categoryNames.map(
                          (category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText: 'Precio',
                          hintText: '0.00',
                          prefixText: '\$ ',
                          prefixIcon: Icon(
                            Icons.attach_money,
                          ),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title: const Text(
                          'Disponible para venta',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          available
                              ? 'Se mostrará al levantar pedidos.'
                              : 'No se podrá seleccionar en pedidos.',
                        ),
                        value: available,
                        onChanged: (value) {
                          setDialogState(() {
                            available = value;
                          });
                        },
                      ),
                      const Divider(height: 30),
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Grupos de opciones',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Agrega sabores, tamaños o ingredientes.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Agregar grupo de opciones',
                            onSelected: (value) async {
                              KomandaProductOptionGroup? group;

                              if (value == 'manual') {
                                group = await _openOptionGroupDialog(context);
                              } else if (value == 'products') {
                                group = await _openLinkedProductsGroupDialog(
                                  context,
                                  state.products,
                                  currentProductId: product?.id,
                                );
                              } else if (value == 'catalog') {
                                group = await _openCatalogGroupDialog(
                                  context,
                                  state.optionCatalogs,
                                );
                              }

                              if (group == null) return;

                              setDialogState(() {
                                groups.add(group!);
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem<String>(
                                value: 'catalog',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.tune_rounded),
                                  title: Text('Usar configuración'),
                                  subtitle: Text('Carnes, rellenos, sabores, etc.'),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'manual',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.edit_note_rounded),
                                  title: Text('Opciones manuales'),
                                  subtitle: Text('Ej. Con todo / Sin cebolla'),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'products',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.account_tree_outlined),
                                  title: Text('Combinar productos'),
                                  subtitle: Text('Usa productos ya registrados'),
                                ),
                              ),
                            ],
                            child: const Chip(
                              avatar: Icon(Icons.add, size: 18),
                              label: Text('Agregar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (groups.isEmpty)
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.45),
                          ),
                          child: const Text(
                            'Producto simple: no requiere '
                            'seleccionar opciones.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ...groups.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final group = entry.value;

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              top: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                group.name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(
                                  top: 5,
                                ),
                                child: Text(
                                  '${group.catalogName.isNotEmpty ? 'Configuración: ${group.catalogName}' : group.options.join(' · ')}\n'
                                  '${group.multiple ? 'Selección múltiple' : 'Selección única'}'
                                  '${group.required ? ' · Obligatorio' : ' · Opcional'}',
                                ),
                              ),
                              trailing: Wrap(
                                children: [
                                  IconButton(
                                    tooltip:
                                        'Editar grupo',
                                    onPressed:
                                        () async {
                                      final edited = group.catalogId.isNotEmpty
                                          ? await _openCatalogGroupDialog(
                                              context,
                                              state.optionCatalogs,
                                              group: group,
                                            )
                                          : await _openOptionGroupDialog(
                                              context,
                                              group: group,
                                            );

                                      if (edited == null) {
                                        return;
                                      }

                                      setDialogState(() {
                                        groups[index] =
                                            edited;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip:
                                        'Eliminar grupo',
                                    onPressed: () {
                                      setDialogState(() {
                                        groups.removeAt(
                                          index,
                                        );
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (validationMessage != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 14,
                          ),
                          child: Text(
                            validationMessage!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final productName =
                        nameController.text.trim();

                    final normalizedPrice =
                        priceController.text
                            .trim()
                            .replaceAll(',', '.');

                    final amount =
                        double.tryParse(normalizedPrice);

                    if (productName.isEmpty) {
                      setDialogState(() {
                        validationMessage =
                            'Escribe el nombre del producto.';
                      });
                      return;
                    }

                    if (selectedCategory
                        .trim()
                        .isEmpty) {
                      setDialogState(() {
                        validationMessage =
                            'Selecciona una categoría.';
                      });
                      return;
                    }

                    if (amount == null || amount < 0) {
                      setDialogState(() {
                        validationMessage =
                            'Captura un precio válido.';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      KomandaProduct(
                        id: product?.id ??
                            DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                        name: productName,
                        category:
                            selectedCategory,
                        price: amount,
                        available: available,
                        optionGroups:
                            List<
                                KomandaProductOptionGroup>.from(
                          groups,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    priceController.dispose();

    if (savedProduct == null ||
        !context.mounted) {
      return;
    }

    context.read<KomandaBloc>().add(
          KomandaProductSaved(savedProduct),
        );
  }

  Future<KomandaProductOptionGroup?> _openLinkedProductsGroupDialog(
    BuildContext context,
    List<KomandaProduct> allProducts, {
    String? currentProductId,
  }) async {
    final nameController = TextEditingController();
    final searchController = TextEditingController();

    final candidates = allProducts
        .where((item) =>
            item.available &&
            item.id != currentProductId &&
            item.name.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final categories = <String>{
      'Todas',
      ...candidates.map((item) => item.category.trim()).where((e) => e.isNotEmpty),
    }.toList();

    String categoryFilter = 'Todas';
    final selectedIds = <String>{};
    bool multiple = false;
    bool requiredSelection = true;
    String? validationMessage;

    final result = await showDialog<KomandaProductOptionGroup>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchController.text.trim().toLowerCase();
            final visible = candidates.where((item) {
              final matchesCategory = categoryFilter == 'Todas' || item.category == categoryFilter;
              final matchesSearch = query.isEmpty ||
                  item.name.toLowerCase().contains(query) ||
                  item.category.toLowerCase().contains(query);
              return matchesCategory && matchesSearch;
            }).toList();

            final canSave = nameController.text.trim().isNotEmpty && selectedIds.isNotEmpty;

            return AlertDialog(
              title: const Text('Combinar productos registrados'),
              content: SizedBox(
                width: 620,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crea un grupo usando productos que ya existen. Ejemplo: en un Taco/Torta crea el grupo “Tipo de carne” y selecciona Buche, Lengua, Cachete, etc.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Nombre del grupo',
                          hintText: 'Ej. Tipo de carne o Presentación',
                          prefixIcon: Icon(Icons.account_tree_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: categoryFilter,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Filtrar categoría',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: categories
                                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                                  .toList(),
                              onChanged: (value) => setDialogState(() {
                                categoryFilter = value ?? 'Todas';
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (_) => setDialogState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Buscar producto',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Permitir varias'),
                              subtitle: const Text('Ej. combinar dos carnes'),
                              value: multiple,
                              onChanged: (value) => setDialogState(() => multiple = value),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Obligatorio'),
                              value: requiredSelection,
                              onChanged: (value) => setDialogState(() => requiredSelection = value),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        '${selectedIds.length} producto(s) seleccionado(s)',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: visible.isEmpty
                            ? const Center(child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('No hay productos que coincidan.'),
                              ))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  final item = visible[index];
                                  final checked = selectedIds.contains(item.id);
                                  return CheckboxListTile(
                                    dense: true,
                                    value: checked,
                                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text('${item.category} · ${komandaMoney(item.price)}'),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          selectedIds.add(item.id);
                                        } else {
                                          selectedIds.remove(item.id);
                                        }
                                        validationMessage = null;
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      if (validationMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            validationMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: canSave
                      ? () {
                          final selectedProducts = candidates
                              .where((item) => selectedIds.contains(item.id))
                              .toList();
                          if (selectedProducts.isEmpty) {
                            setDialogState(() => validationMessage = 'Selecciona al menos un producto.');
                            return;
                          }

                          Navigator.pop(
                            dialogContext,
                            KomandaProductOptionGroup(
                              id: DateTime.now().microsecondsSinceEpoch.toString(),
                              name: nameController.text.trim(),
                              options: selectedProducts.map((item) => item.name).toList(),
                              optionDetails: selectedProducts.map((item) => KomandaProductOption(id: '', label: item.name, linkedProductId: item.id)).toList(),
                              multiple: multiple,
                              required: requiredSelection,
                              minSelections: requiredSelection ? 1 : 0,
                              maxSelections: multiple ? null : 1,
                              allowRepeats: multiple,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Crear combinación'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    searchController.dispose();
    return result;
  }

  Future<KomandaProductOptionGroup?> _openCatalogGroupDialog(
    BuildContext context,
    List<KomandaOptionCatalog> catalogs, {
    KomandaProductOptionGroup? group,
  }) async {
    final activeCatalogs = catalogs.where((c) => c.active && c.values.any((v) => v.active)).toList();
    if (activeCatalogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea una configuración desde Administrar productos > Configuraciones.')),
      );
      return null;
    }

    String catalogId = group?.catalogId.isNotEmpty == true
        ? group!.catalogId
        : activeCatalogs.first.id;
    final nameController = TextEditingController(text: group?.name ?? activeCatalogs.first.name);
    var multiple = group?.multiple ?? false;
    var requiredSelection = group?.required ?? true;
    var minSelections = group?.minSelections ?? 1;
    int? maxSelections = group?.maxSelections ?? 1;

    final result = await showDialog<KomandaProductOptionGroup>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setD) {
          final catalog = activeCatalogs.firstWhere(
            (c) => c.id == catalogId,
            orElse: () => activeCatalogs.first,
          );
          final values = catalog.values.where((v) => v.active).toList();
          return AlertDialog(
            title: Text(group == null ? 'Usar configuración' : 'Editar configuración del producto'),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: catalog.id,
                      decoration: const InputDecoration(
                        labelText: 'Configuración',
                        prefixIcon: Icon(Icons.tune_rounded),
                      ),
                      items: activeCatalogs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (value) => setD(() {
                        if (value == null) return;
                        catalogId = value;
                        final selectedCatalog = activeCatalogs.firstWhere((c) => c.id == value);
                        if (group == null || nameController.text.trim() == catalog.name) {
                          nameController.text = selectedCatalog.name;
                        }
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Texto que verá el usuario',
                        hintText: 'Ej. Carne(s), Relleno o Sabor',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        values.map((v) => v.label).join(' · '),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Permitir varias selecciones'),
                      value: multiple,
                      onChanged: (v) => setD(() {
                        multiple = v;
                        if (!multiple) maxSelections = 1;
                        if (multiple && maxSelections == 1) maxSelections = null;
                      }),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Obligatorio'),
                      value: requiredSelection,
                      onChanged: (v) => setD(() {
                        requiredSelection = v;
                        if (v && minSelections < 1) minSelections = 1;
                        if (!v) minSelections = 0;
                      }),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(
                onPressed: nameController.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(
                          dialogContext,
                          KomandaProductOptionGroup(
                            id: group?.id ?? 'local_${DateTime.now().microsecondsSinceEpoch}',
                            name: nameController.text.trim(),
                            catalogId: catalog.id,
                            catalogName: catalog.name,
                            options: values.map((v) => v.label).toList(),
                            optionDetails: values.map((v) => KomandaProductOption(
                              id: v.id,
                              label: v.label,
                              extraPrice: v.extraPrice,
                              complementId: v.complementId,
                              linkedProductId: v.linkedProductId,
                              defaultQuantity: v.defaultQuantity,
                            )).toList(),
                            multiple: multiple,
                            required: requiredSelection,
                            minSelections: requiredSelection ? (minSelections < 1 ? 1 : minSelections) : 0,
                            maxSelections: multiple ? maxSelections : 1,
                            allowRepeats: false,
                          ),
                        ),
                child: const Text('Usar configuración'),
              ),
            ],
          );
        },
      ),
    );
    nameController.dispose();
    return result;
  }

  Future<KomandaProductOptionGroup?>
      _openOptionGroupDialog(
    BuildContext context, {
    KomandaProductOptionGroup? group,
  }) async {
    final nameController = TextEditingController(
      text: group?.name ?? '',
    );

    final optionController =
        TextEditingController();

    final options = <String>[
      ...?group?.options,
    ];

    bool multiple = group?.multiple ?? false;
    bool requiredSelection =
        group?.required ?? false;

    String? validationMessage;

    final result =
        await showDialog<KomandaProductOptionGroup>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final canSave =
                nameController.text.trim().isNotEmpty &&
                    options.isNotEmpty;

            void addCurrentOption() {
              final value =
                  optionController.text.trim();

              if (value.isEmpty) return;

              final alreadyExists = options.any(
                (currentOption) =>
                    currentOption.toLowerCase() ==
                    value.toLowerCase(),
              );

              if (alreadyExists) {
                setDialogState(() {
                  validationMessage =
                      'Esa opción ya fue agregada.';
                });
                return;
              }

              setDialogState(() {
                options.add(value);
                optionController.clear();
                validationMessage = null;
              });
            }

            return AlertDialog(
              title: Text(
                group == null
                    ? 'Nuevo grupo de opciones'
                    : 'Editar grupo de opciones',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        textCapitalization:
                            TextCapitalization.sentences,
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Nombre del grupo',
                          hintText:
                              'Ejemplo: Sabor',
                          prefixIcon: Icon(
                            Icons.tune_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                                  optionController,
                              textCapitalization:
                                  TextCapitalization
                                      .sentences,
                              onSubmitted: (_) {
                                addCurrentOption();
                              },
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Nueva opción',
                                hintText:
                                    'Ejemplo: Jamaica',
                                helperText:
                                    'Pulsa Enter o el botón +',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip:
                                'Agregar opción',
                            onPressed:
                                addCurrentOption,
                            icon: const Icon(
                              Icons.add,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (options.isEmpty)
                        const Text(
                          'Agrega al menos una opción.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: options.map(
                          (option) {
                            return InputChip(
                              label: Text(option),
                              avatar: const Icon(
                                Icons
                                    .check_circle_outline,
                                size: 18,
                              ),
                              onDeleted: () {
                                setDialogState(() {
                                  options.remove(
                                    option,
                                  );
                                });
                              },
                            );
                          },
                        ).toList(),
                      ),
                      const Divider(height: 30),
                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title: const Text(
                          'Permitir seleccionar varias',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Ejemplo: queso extra y tocino.',
                        ),
                        value: multiple,
                        onChanged: (value) {
                          setDialogState(() {
                            multiple = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title: const Text(
                          'Selección obligatoria',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'No permitirá continuar sin '
                          'seleccionar una opción.',
                        ),
                        value: requiredSelection,
                        onChanged: (value) {
                          setDialogState(() {
                            requiredSelection = value;
                          });
                        },
                      ),
                      if (validationMessage != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Text(
                            validationMessage!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: canSave
                      ? () {
                          Navigator.pop(
                            dialogContext,
                            KomandaProductOptionGroup(
                              id: group?.id ??
                                  DateTime.now()
                                      .microsecondsSinceEpoch
                                      .toString(),
                              name: nameController
                                  .text
                                  .trim(),
                              options:
                                  List<String>.from(
                                options,
                              ),
                              multiple: multiple,
                              required:
                                  requiredSelection,
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    group == null
                        ? 'Agregar grupo'
                        : 'Guardar cambios',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    optionController.dispose();

    return result;
  }
}
