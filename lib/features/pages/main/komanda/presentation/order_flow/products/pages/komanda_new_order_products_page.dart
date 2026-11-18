import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/routes/route_names.dart';
import '../../../../domain/entities/komanda_product.dart';
import '../../../bloc/komanda_bloc.dart';
import '../../../bloc/komanda_event.dart';
import '../../../bloc/komanda_state.dart';
import '../../../shared/widgets/komanda_widgets.dart';

class KomandaNewOrderProductsPage extends StatefulWidget {
  const KomandaNewOrderProductsPage({super.key});

  @override
  State<KomandaNewOrderProductsPage> createState() =>
      _KomandaNewOrderProductsPageState();
}

class _KomandaNewOrderProductsPageState
    extends State<KomandaNewOrderProductsPage> {
  final searchController = TextEditingController();
  String category = 'Todos';
  bool _initialCategoryApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<KomandaBloc>().add(const KomandaRefreshed());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _addProduct(
    BuildContext context,
    KomandaProduct product,
    List<KomandaProduct> allProducts,
  ) async {
    // ============================================================
    // PAQUETE
    // ============================================================
    // Un paquete NO se agrega directamente. Primero se eligen sus
    // componentes y después se configura CADA unidad de esos productos.
    // Ejemplo:
    //   Paquete -> 1 Torta + 2 Tacos + 1 Bebida
    //   Torta   -> Carne(s): Lengua / Buche
    //   Taco #1 -> Relleno: Papa / Carne: Cachete
    //   Taco #2 -> Relleno: Frijol / Carne: Lengua
    //   Bebida  -> Sabor / tipo cuando tenga opciones.
    // ============================================================
    if (product.isPackage) {
      final packageItems = await showModalBottomSheet<List<_PackageSelectionItem>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PackageCompositionSheet(
          product: product,
          allProducts: allProducts,
        ),
      );

      if (!context.mounted || packageItems == null) return;

      final specifications = <String>[];
      double calculatedPrice = 0;
      final occurrenceByProduct = <String, int>{};

      for (var index = 0; index < packageItems.length; index++) {
        final selectedItem = packageItems[index];

        // Primero intentamos resolver por ID real.
        KomandaProduct? linked;
        if (selectedItem.productId.trim().isNotEmpty) {
          linked = allProducts
              .where((p) => p.id == selectedItem.productId)
              .firstOrNull;
        }

        // Compatibilidad con datos viejos / paquetes que solo tengan label.
        linked ??= allProducts
            .where(
              (p) =>
                  p.name.trim().toLowerCase() ==
                  selectedItem.productName.trim().toLowerCase(),
            )
            .firstOrNull;

        if (linked == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No se encontró el producto "${selectedItem.productName}" del paquete. '
                  'Actualiza el catálogo e inténtalo nuevamente.',
                ),
              ),
            );
          }
          return;
        }

        final key = linked.id.isNotEmpty ? linked.id : linked.name;
        occurrenceByProduct[key] = (occurrenceByProduct[key] ?? 0) + 1;
        final occurrence = occurrenceByProduct[key]!;

        final totalSameProduct = packageItems.where((item) {
          if (selectedItem.productId.isNotEmpty && item.productId.isNotEmpty) {
            return item.productId == selectedItem.productId;
          }
          return item.productName.trim().toLowerCase() ==
              selectedItem.productName.trim().toLowerCase();
        }).length;

        final unitLabel = totalSameProduct > 1
            ? '${linked.printName} #$occurrence'
            : linked.printName;

        List<String> nestedSpecifications = const [];

        // IMPORTANTE: usamos directamente los grupos configurables del
        // producto enlazado. Esto hace que dentro de un paquete se comporte
        // EXACTAMENTE igual que al agregar el producto individualmente.
        final configurableGroups = linked.selectableOptionGroups;

        if (configurableGroups.isNotEmpty) {
          final selected = await showModalBottomSheet<List<String>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ProductCombinationSheet(
              product: linked!,
              titleOverride: 'Configura $unitLabel',
              subtitleOverride:
                  'Este producto forma parte de ${product.printName}.',
            ),
          );

          // Cancelar una combinación cancela el agregado completo del paquete.
          if (!context.mounted || selected == null) return;
          nestedSpecifications = selected;
        }

        calculatedPrice += linked.price;

        if (nestedSpecifications.isEmpty) {
          specifications.add('Paquete · $unitLabel');
        } else {
          specifications.add(
            'Paquete · $unitLabel → ${nestedSpecifications.join(' · ')}',
          );
        }
      }

      final productForCart = product.pricingMode == 'components'
          ? product.copyWith(price: calculatedPrice)
          : product;

      if (!context.mounted) return;
      context.read<KomandaBloc>().add(
            KomandaConfiguredProductAdded(
              product: productForCart,
              specifications: specifications,
            ),
          );
      return;
    }

    // ============================================================
    // PRODUCTO NORMAL
    // ============================================================
    if (!product.hasOptions) {
      context.read<KomandaBloc>().add(KomandaProductAdded(product));
      return;
    }

    final specifications = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductCombinationSheet(product: product),
    );

    if (!context.mounted || specifications == null) return;

    context.read<KomandaBloc>().add(
          KomandaConfiguredProductAdded(
            product: product,
            specifications: specifications,
          ),
        );
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final categories = <String>{
          'Todos',
          ...state.products.map((e) => e.category),
        }.toList();

        // Restaurante 3: abrir por defecto la categoría Tacos, una sola vez.
        // Los demás restaurantes conservan el filtro Todos.
        if (!_initialCategoryApplied && state.products.isNotEmpty) {
          _initialCategoryApplied = true;
          if (context.read<KomandaBloc>().restaurantId.trim() == '3') {
            final tacosCategory = categories.where(
              (name) => name.trim().toLowerCase() == 'tacos',
            ).firstOrNull;
            if (tacosCategory != null) category = tacosCategory;
          }
        }

        final query = searchController.text.trim().toLowerCase();
        final products = state.products.where((item) {
          final matchesCategory =
              category == 'Todos' || item.category == category;
          final matchesSearch = query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query);
          return item.available && matchesCategory && matchesSearch;
        }).toList();

        // Restaurante 3: tacos de barbacoa, carnes y quesos, en ese orden.
        if (context.read<KomandaBloc>().restaurantId.trim() == '3' &&
            category.trim().toLowerCase() == 'tacos') {
          int tacoPriority(String name) {
            final normalized = name.toLowerCase();
            if (normalized.contains('queso') || normalized.contains('quesadilla')) return 2;
            if (normalized.contains('barbacoa')) return 0;
            return 1;
          }
          products.sort((a, b) {
            final priority = tacoPriority(a.name).compareTo(tacoPriority(b.name));
            return priority != 0 ? priority : a.name.compareTo(b.name);
          });
        }

        return KomandaPageShell(
          title: 'Productos · ${state.selectedTable}',
          actions: [
            IconButton(
              tooltip: 'Vaciar carrito',
              onPressed: state.cart.isEmpty
                  ? null
                  : () => context
                      .read<KomandaBloc>()
                      .add(const KomandaCartCleared()),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
          children: [
            KMetricCard(
              label: 'Total carrito',
              value: money(state.cartTotal),
              icon: Icons.shopping_cart,
            ),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar producto o categoría...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final value = categories[index];
                  return ChoiceChip(
                    label: Text(value),
                    selected: category == value,
                    onSelected: (_) => setState(() => category = value),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            if (products.isEmpty)
              const KCard(
                child: Text('No hay productos que coincidan con los filtros.'),
              ),
            for (final product in products)
              Builder(
                builder: (context) {
                  final entries = state.cart.entries
                      .where((entry) => entry.value.productId == product.id)
                      .toList();
                  final quantity = entries.fold<int>(
                    0,
                    (sum, entry) => sum + entry.value.quantity,
                  );
                  final lastKey = entries.isEmpty ? null : entries.last.key;

                  return KCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${product.category} · ${money(product.price)}',
                              ),
                              if (product.isPackage)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.inventory_2_outlined, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Paquete · ${product.packageItemLabels.join(' + ')}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (product.hasOptions)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.tune_rounded,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${product.selectableOptionGroups.length} combinación${product.selectableOptionGroups.length == 1 ? '' : 'es'} disponible${product.selectableOptionGroups.length == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: lastKey == null
                              ? null
                              : () => context.read<KomandaBloc>().add(
                                    KomandaProductRemoved(lastKey),
                                  ),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        IconButton(
                          tooltip: product.hasOptions
                              ? 'Elegir combinación'
                              : 'Agregar producto',
                          onPressed: () => _addProduct(context, product, state.products),
                          icon: Icon(
                            product.hasOptions
                                ? Icons.tune_rounded
                                : Icons.add_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            KPrimaryButton(
              text: 'Ver resumen',
              onPressed: state.cart.isEmpty
                  ? null
                  : () => Navigator.pushNamed(
                        context,
                        RouteNames.komandaOrderSummary,
                      ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductCombinationSheet extends StatefulWidget {
  final KomandaProduct product;
  final String? titleOverride;
  final String? subtitleOverride;

  const _ProductCombinationSheet({
    required this.product,
    this.titleOverride,
    this.subtitleOverride,
  });

  @override
  State<_ProductCombinationSheet> createState() =>
      _ProductCombinationSheetState();
}

class _ProductCombinationSheetState
    extends State<_ProductCombinationSheet> {
  late final Map<String, Set<String>> selected;

  @override
  void initState() {
    super.initState();
    selected = <String, Set<String>>{};

    for (final group in widget.product.selectableOptionGroups) {
      selected[group.id] = <String>{};
    }
  }

  bool get isValid => widget.product.selectableOptionGroups.every((group) {
        final count = selected[group.id]?.length ?? 0;
        final min = group.required
            ? (group.minSelections <= 0 ? 1 : group.minSelections)
            : group.minSelections;
        final max = _isCornejoMeat(group) ? null : group.maxSelections;
        if (count < min) return false;
        if (max != null && max > 0 && count > max) return false;
        return true;
      });

  bool _isCornejoMeat(KomandaProductOptionGroup group) {
    if (context.read<KomandaBloc>().restaurantId.trim() != '2') return false;
    final name = '${group.name} ${group.catalogName}'.toLowerCase();
    return name.contains('carne');
  }

  bool _allowsMultiple(KomandaProductOptionGroup group) =>
      group.multiple || _isCornejoMeat(group);

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
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 10, 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.restaurant_menu_rounded),
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
                          ),
                        ),
                        Text(
                          widget.subtitleOverride ??
                              'Elige las combinaciones de esta unidad.',
                          style: const TextStyle(fontWeight: FontWeight.w600),
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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: KCard(
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
                                    ),
                                  ),
                                ),
                                if (group.required)
                                  const Text(
                                    'Obligatorio',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _allowsMultiple(group)
                                  ? 'Puedes seleccionar varias opciones.'
                                  : 'Selecciona una opción.',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.labels.map((option) {
                                final active = values.contains(option);

                                return FilterChip(
                                  selected: active,
                                  label: Text(option),
                                  onSelected: (_) {
                                    setState(() {
                                      final groupValues =
                                          selected[group.id] ?? <String>{};

                                      if (_allowsMultiple(group)) {
                                        active
                                            ? groupValues.remove(option)
                                            : groupValues.add(option);
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
                            final values = selected[group.id] ?? <String>{};
                            for (final value in values) {
                              specifications.add('${group.name}: $value');
                            }
                          }

                          Navigator.pop(context, specifications);
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Agregar con esta combinación'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageSelectionItem {
  final String productId;
  final String productName;

  const _PackageSelectionItem({
    required this.productId,
    required this.productName,
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

class _PackageCompositionSheetState
    extends State<_PackageCompositionSheet> {
  late final Map<String, Map<String, int>> counts;

  @override
  void initState() {
    super.initState();
    counts = {
      for (final group in widget.product.packageGroups)
        group.id: <String, int>{},
    };
  }

  String _optionKey(KomandaProductOption option) {
    if (option.linkedProductId.trim().isNotEmpty) {
      return 'id:${option.linkedProductId.trim()}';
    }
    return 'name:${option.label.trim().toLowerCase()}';
  }

  KomandaProduct? _linkedProduct(KomandaProductOption option) {
    if (option.linkedProductId.trim().isNotEmpty) {
      final byId = widget.allProducts
          .where((p) => p.id == option.linkedProductId.trim())
          .firstOrNull;
      if (byId != null) return byId;
    }

    return widget.allProducts
        .where(
          (p) =>
              p.name.trim().toLowerCase() == option.label.trim().toLowerCase(),
        )
        .firstOrNull;
  }

  int totalFor(KomandaProductOptionGroup group) =>
      counts[group.id]!.values.fold(0, (a, b) => a + b);

  bool get valid => widget.product.packageGroups.every((group) {
        final count = totalFor(group);
        final min = group.minSelections > 0
            ? group.minSelections
            : (group.required ? 1 : 0);
        final max = _isCornejoMeat(group) ? null : group.maxSelections;
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
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 10, 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.inventory_2_outlined),
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
                          ),
                        ),
                        const Text(
                          '1. Elige los productos. 2. Configura cada producto del paquete.',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
                  final max = _isCornejoMeat(group) ? null : group.maxSelections;
                  final current = totalFor(group);
                  final requirement = max != null && max == min
                      ? 'Elige $max'
                      : max == null
                          ? 'Mínimo $min'
                          : '$min a $max';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: KCard(
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
                                  ),
                                ),
                              ),
                              Text(
                                '$current · $requirement',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...group.optionDetails.map((option) {
                            final key = _optionKey(option);
                            final amount = counts[group.id]![key] ?? 0;
                            final linked = _linkedProduct(option);
                            final hasComplements =
                                linked?.selectableOptionGroups.isNotEmpty ?? false;
                            final canAdd = max == null || current < max;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                leading: Icon(
                                  hasComplements
                                      ? Icons.tune_rounded
                                      : Icons.restaurant_menu_rounded,
                                ),
                                title: Text(
                                  option.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: hasComplements
                                    ? Text(
                                        'Después elegirás ${linked!.selectableOptionGroups.map((g) => g.name).join(', ')}',
                                        style: const TextStyle(fontSize: 11),
                                      )
                                    : const Text(
                                        'Sin complementos adicionales',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: amount <= 0
                                          ? null
                                          : () => setState(() {
                                                counts[group.id]![key] =
                                                    amount - 1;
                                              }),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
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
                                                counts[group.id]![key] =
                                                    amount + 1;
                                              }),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: !valid
                      ? null
                      : () {
                          final result = <_PackageSelectionItem>[];

                          for (final group in widget.product.packageGroups) {
                            for (final option in group.optionDetails) {
                              final key = _optionKey(option);
                              final amount = counts[group.id]![key] ?? 0;

                              for (var i = 0; i < amount; i++) {
                                result.add(
                                  _PackageSelectionItem(
                                    productId: option.linkedProductId,
                                    productName: option.label,
                                  ),
                                );
                              }
                            }
                          }

                          Navigator.pop(context, result);
                        },
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Continuar y configurar complementos'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullProduct on Iterable<KomandaProduct> {
  KomandaProduct? get firstOrNull => isEmpty ? null : first;
}

