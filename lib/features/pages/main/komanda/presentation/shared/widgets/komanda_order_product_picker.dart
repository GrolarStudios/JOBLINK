import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/komanda_bloc.dart';

import '../../../core/komanda_theme.dart';
import '../../../core/utils/komanda_money.dart';
import '../../../domain/entities/komanda_order.dart';
import '../../../domain/entities/komanda_product.dart';

Future<KomandaOrderItem?> showKomandaOrderProductPicker({
  required BuildContext context,
  required List<KomandaProduct> products,
  required int plateNumber,
}) async {
  final selected = await showDialog<KomandaProduct>(
    context: context,
    builder: (dialogContext) => _ProductCatalogDialog(products: products),
  );
  if (selected == null || !context.mounted) return null;

  var productForOrder = selected;
  final specifications = <String>['Plato $plateNumber'];

  if (selected.isPackage) {
    final packageSpecs = await _configurePackage(context, selected, products);
    if (!context.mounted || packageSpecs == null) return null;
    specifications.addAll(packageSpecs);
  }

  if (!selected.isPackage && _isMeatByWeight(selected)) {
    final amount = await _selectMeatAmount(context, pricePerKg: selected.price);
    if (!context.mounted || amount == null) return null;
    specifications.add('Peso: ${_formatKilograms(amount.kilograms)} kg');
    if (!_isChicharron(selected)) {
      specifications.add('Importe carne: ${komandaMoney(amount.amount)}');
    }
    productForOrder = selected.copyWith(price: amount.amount);
  }

  if (!selected.isPackage && selected.hasOptions) {
    final optionSpecs = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductOptionsSheet(
        product: selected,
        availableProducts: products,
      ),
    );
    if (!context.mounted || optionSpecs == null) return null;
    specifications.addAll(optionSpecs);
    productForOrder = productForOrder.copyWith(
      price: productForOrder.price + _selectedExtrasPrice(selected, optionSpecs),
    );
  }

  final config = await _showAddConfiguration(
    context,
    productName: selected.name,
    specifications: specifications,
  );
  if (!context.mounted || config == null) return null;

  if (config.note.trim().isNotEmpty) {
    specifications.add('Nota: ${config.note.trim()}');
  }

  return KomandaOrderItem(
    productId: selected.id,
    name: selected.printName,
    category: selected.category,
    quantity: config.quantity,
    unitPrice: productForOrder.price,
    specifications: specifications,
  );
}


Future<List<String>?> _configurePackage(
  BuildContext context,
  KomandaProduct package,
  List<KomandaProduct> availableProducts,
) async {
  final specs = <String>[];

  for (final group in package.packageGroups) {
    final slotCount = (group.maxSelections ?? group.minSelections) > 0
        ? (group.maxSelections ?? group.minSelections)
        : 1;
    final options = group.optionDetails.where((o) {
      final linked = _resolveLinkedProduct(availableProducts, o);
      return linked == null || linked.available;
    }).toList();

    if (options.isEmpty) {
      if (group.required) return null;
      continue;
    }

    for (var slot = 1; slot <= slotCount; slot++) {
      KomandaProductOption? selectedOption;
      if (options.length == 1) {
        selectedOption = options.first;
      } else {
        selectedOption = await showDialog<KomandaProductOption>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(slotCount > 1 ? '${group.name} $slot de $slotCount' : group.name),
            content: SizedBox(
              width: 500,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, index) {
                  final option = options[index];
                  final linked = _resolveLinkedProduct(availableProducts, option);
                  return ListTile(
                    title: Text(linked?.printName ?? option.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: linked == null ? null : Text(linked.category),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(dialogContext, option),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ],
          ),
        );
        if (!context.mounted || selectedOption == null) return null;
      }
      if (selectedOption == null) return null;

      final linked = _resolveLinkedProduct(availableProducts, selectedOption);
      final childName = linked?.printName ?? selectedOption.label;
      final slotLabel = slotCount > 1 ? '${group.name} $slot' : group.name;
      specs.add('$slotLabel: $childName');

      if (linked != null && linked.hasOptions) {
        final childSpecs = await _configurePackageChild(
          context: context,
          slotLabel: slotLabel,
          product: linked,
          availableProducts: availableProducts,
        );
        if (!context.mounted || childSpecs == null) return null;
        for (final childSpec in childSpecs) {
          specs.add('$slotLabel · $childSpec');
        }
      }
    }
  }

  return specs;
}

Future<List<String>?> _configurePackageChild({
  required BuildContext context,
  required String slotLabel,
  required KomandaProduct product,
  required List<KomandaProduct> availableProducts,
}) async {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProductOptionsSheet(
      product: product,
      availableProducts: availableProducts,
      titleOverride: '$slotLabel · ${product.printName}',
      confirmLabel: 'Guardar configuración de $slotLabel',
    ),
  );
}

KomandaProduct? _resolveLinkedProduct(
  List<KomandaProduct> availableProducts,
  KomandaProductOption option,
) {
  // Preferimos el producto del catálogo principal porque llega con todos sus
  // grupos/opciones. El linkedProduct anidado puede venir recortado por la
  // protección anti-recursión del backend en paquetes.
  final fromCatalog = _findProductById(availableProducts, option.linkedProductId);
  return fromCatalog ?? option.linkedProduct;
}

KomandaProduct? _findProductById(List<KomandaProduct> products, String id) {
  if (id.trim().isEmpty) return null;
  for (final product in products) {
    if (product.id == id) return product;
  }
  return null;
}

class _ProductCatalogDialog extends StatefulWidget {
  final List<KomandaProduct> products;
  const _ProductCatalogDialog({required this.products});

  @override
  State<_ProductCatalogDialog> createState() => _ProductCatalogDialogState();
}

class _ProductCatalogDialogState extends State<_ProductCatalogDialog> {
  String query = '';
  String category = 'Todos';

  @override
  Widget build(BuildContext context) {
    final categories = <String>{'Todos', ...widget.products.map((e) => e.category)}.toList();
    final filtered = widget.products.where((p) {
      if (!p.available) return false;
      final byCategory = category == 'Todos' || p.category == category;
      final q = query.trim().toLowerCase();
      final byQuery = q.isEmpty || p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q);
      return byCategory && byQuery;
    }).toList();

    return AlertDialog(
      title: const Text('Agregar producto al pedido'),
      content: SizedBox(
        width: 560,
        height: 560,
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
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
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final p = filtered[index];
                  return ListTile(
                    title: Text(p.printName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${p.category} · ${komandaMoney(p.price)}'),
                    trailing: const Icon(Icons.add_circle_outline_rounded),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))],
    );
  }
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

Future<_MeatAmountSelection?> _selectMeatAmount(BuildContext context, {required double pricePerKg}) {
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
        final kilograms = mode == _MeatAmountMode.kilograms ? value : (pricePerKg > 0 ? value / pricePerKg : 0.0);
        final amount = mode == _MeatAmountMode.money ? value : value * pricePerKg;
        final valid = value > 0 && pricePerKg > 0;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cantidad de carne', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text('Precio por kilo: ${komandaMoney(pricePerKg)}'),
                  const SizedBox(height: 12),
                  SegmentedButton<_MeatAmountMode>(
                    segments: const [
                      ButtonSegment(value: _MeatAmountMode.kilograms, label: Text('Kilogramos'), icon: Icon(Icons.scale_outlined)),
                      ButtonSegment(value: _MeatAmountMode.money, label: Text('Cantidad en \$'), icon: Icon(Icons.attach_money_rounded)),
                    ],
                    selected: {mode},
                    onSelectionChanged: (values) => setSheetState(() { mode = values.first; controller.clear(); }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      labelText: mode == _MeatAmountMode.kilograms ? 'Kilogramos' : 'Cantidad de dinero',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(valid ? '${_formatKilograms(kilograms)} kg = ${komandaMoney(amount)}' : 'Ingresa una cantidad mayor a 0',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: KomandaTheme.purple)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: valid ? () => Navigator.pop(sheetContext, _MeatAmountSelection(kilograms: kilograms, amount: amount)) : null,
                      child: const Text('Usar esta cantidad'),
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

String _formatKilograms(double value) {
  var formatted = value.toStringAsFixed(3);
  while (formatted.contains('.') && formatted.endsWith('0')) {
    formatted = formatted.substring(0, formatted.length - 1);
  }
  if (formatted.endsWith('.')) formatted = formatted.substring(0, formatted.length - 1);
  return formatted;
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
      builder: (context, setLocal) => Padding(
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
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: specifications.map((e) => Chip(label: Text(e))).toList()),
                const SizedBox(height: 12),
                Row(children: [
                  const Expanded(child: Text('Repetir esta configuración', style: TextStyle(fontWeight: FontWeight.w900))),
                  IconButton(onPressed: quantity <= 1 ? null : () => setLocal(() => quantity--), icon: const Icon(Icons.remove_circle_outline)),
                  Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  IconButton(onPressed: () => setLocal(() => quantity++), icon: const Icon(Icons.add_circle_outline)),
                ]),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Nota de este producto', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _AddProductConfiguration(quantity: quantity, note: noteController.text)),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(quantity == 1 ? 'Agregar al pedido' : 'Agregar $quantity iguales'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ).whenComplete(noteController.dispose);
}

class _ProductOptionsSheet extends StatefulWidget {
  final KomandaProduct product;
  final List<KomandaProduct> availableProducts;
  final String? titleOverride;
  final String confirmLabel;

  const _ProductOptionsSheet({
    required this.product,
    required this.availableProducts,
    this.titleOverride,
    this.confirmLabel = 'Agregar con estas opciones',
  });

  @override
  State<_ProductOptionsSheet> createState() => _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends State<_ProductOptionsSheet> {
  late final Map<String, Set<String>> selected;

  @override
  void initState() {
    super.initState();
    selected = {for (final group in widget.product.selectableOptionGroups) group.id: <String>{}};
  }

  bool _isCornejoMeat(KomandaProductOptionGroup group) {
    if (context.read<KomandaBloc>().restaurantId.trim() != '2') return false;
    final name = '${group.name} ${group.catalogName}'.toLowerCase();
    return name.contains('carne');
  }

  bool _allowsMultiple(KomandaProductOptionGroup group) =>
      group.multiple || _isCornejoMeat(group);

  List<KomandaProductOption> _availableOptions(KomandaProductOptionGroup group) {
    if (group.optionDetails.isEmpty || widget.availableProducts.isEmpty) return group.optionDetails;
    return group.optionDetails.where((option) {
      final linkedId = option.linkedProductId.trim();
      if (linkedId.isNotEmpty) {
        final matching = widget.availableProducts.where((p) => p.id == linkedId);
        if (matching.isNotEmpty) return matching.first.available;
      }
      final name = option.label.trim().toLowerCase();
      final matching = widget.availableProducts.where((p) => p.name.trim().toLowerCase() == name);
      return matching.isEmpty || matching.first.available;
    }).toList();
  }

  bool get isValid => widget.product.selectableOptionGroups.every((group) {
    final values = selected[group.id] ?? const <String>{};
    final min = group.required ? (group.minSelections <= 0 ? 1 : group.minSelections) : group.minSelections;
    final max = _isCornejoMeat(group) ? null : group.maxSelections;
    if (values.length < min) return false;
    if (max != null && max > 0 && values.length > max) return false;
    return true;
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
        decoration: const BoxDecoration(color: Color(0xFFF8F7FC), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 10, 12),
              child: Row(children: [
                Expanded(child: Text(widget.titleOverride ?? widget.product.printName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: widget.product.selectableOptionGroups.map((group) {
                    final values = selected[group.id] ?? <String>{};
                    final options = group.optionDetails.isEmpty
                        ? group.options
                        : _availableOptions(group).map((e) => e.label).toList();
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: options.map((option) {
                                final active = values.contains(option);
                                return FilterChip(
                                  selected: active,
                                  label: Text(option),
                                  onSelected: (_) => setState(() {
                                    final set = selected[group.id] ?? <String>{};
                                    if (_allowsMultiple(group)) {
                                      if (active) {
                                        set.remove(option);
                                      } else {
                                        final max = _isCornejoMeat(group) ? null : group.maxSelections;
                                        if (max == null || max <= 0 || set.length < max) {
                                          set.add(option);
                                        }
                                      }
                                    } else {
                                      set..clear()..add(option);
                                    }
                                    selected[group.id] = set;
                                  }),
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
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isValid ? () {
                    final specs = <String>[];
                    for (final group in widget.product.selectableOptionGroups) {
                      for (final value in selected[group.id] ?? const <String>{}) {
                        specs.add('${group.name}: $value');
                      }
                    }
                    Navigator.pop(context, specs);
                  } : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(widget.confirmLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
