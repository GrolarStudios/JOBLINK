import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/komanda_option_catalog.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';

class KomandaOptionCatalogsPage extends StatelessWidget {
  const KomandaOptionCatalogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) => KomandaPhoneFrame(
        child: Column(
          children: [
            const KomandaHeader(
              title: 'Configuraciones de productos',
              subtitle: 'Carnes, rellenos, sabores y cualquier lista reutilizable',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear configuración'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: state.optionCatalogs.isEmpty
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no hay configuraciones.\nCrea una para Carnes, Rellenos, Sabores de aguas, etc.',
                        textAlign: TextAlign.center,
                      ),
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.optionCatalogs.length,
                      itemBuilder: (context, index) {
                        final catalog = state.optionCatalogs[index];
                        return KomandaCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Icon(catalog.active ? Icons.tune_rounded : Icons.tune_outlined),
                            ),
                            title: Text(catalog.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                            subtitle: Text(
                              catalog.values.isEmpty
                                  ? 'Sin opciones'
                                  : catalog.values.where((e) => e.active).map((e) => e.label).join(' · '),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => _edit(context, catalog),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () => _delete(context, catalog),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static int _carneFirstCompare(String a, String b) {
    final av = a.trim().toLowerCase();
    final bv = b.trim().toLowerCase();
    if (av == 'carne' && bv != 'carne') return -1;
    if (bv == 'carne' && av != 'carne') return 1;
    return av.compareTo(bv);
  }

  Future<void> _edit(BuildContext context, [KomandaOptionCatalog? current]) async {
    final name = TextEditingController(text: current?.name ?? '');
    final option = TextEditingController();
    final values = <KomandaOptionCatalogValue>[...?current?.values]..sort((a,b)=>_carneFirstCompare(a.label,b.label));
    var active = current?.active ?? true;
    String? error;

    final result = await showDialog<KomandaOptionCatalog>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setD) {
          void addValue() {
            final label = option.text.trim();
            if (label.isEmpty) return;
            if (values.any((e) => e.label.trim().toLowerCase() == label.toLowerCase())) {
              setD(() => error = 'Esa opción ya existe.');
              return;
            }
            setD(() {
              values.add(KomandaOptionCatalogValue(
                id: 'local_${DateTime.now().microsecondsSinceEpoch}',
                label: label,
                sortOrder: values.length,
              ));
              values.sort((a,b)=>_carneFirstCompare(a.label,b.label));
              option.clear();
              error = null;
            });
          }

          return AlertDialog(
            title: Text(current == null ? 'Nueva configuración' : 'Editar configuración'),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      autofocus: true,
                      onChanged: (_) => setD(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej. Sabores de aguas',
                        prefixIcon: Icon(Icons.tune_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activa'),
                      value: active,
                      onChanged: (v) => setD(() => active = v),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: option,
                            onSubmitted: (_) => addValue(),
                            decoration: const InputDecoration(
                              labelText: 'Agregar opción',
                              hintText: 'Ej. Horchata',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: addValue,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    const SizedBox(height: 10),
                    ...values.asMap().entries.map((entry) {
                      final index = entry.key;
                      final value = entry.value;
                      return Card(
                        child: ListTile(
                          dense: true,
                          title: Text(value.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                          leading: Icon(value.active ? Icons.check_circle_outline : Icons.block),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                tooltip: value.active ? 'Desactivar' : 'Activar',
                                onPressed: () => setD(() {
                                  values[index] = KomandaOptionCatalogValue(
                                    id: value.id,
                                    label: value.label,
                                    active: !value.active,
                                    sortOrder: value.sortOrder,
                                    extraPrice: value.extraPrice,
                                    complementId: value.complementId,
                                    linkedProductId: value.linkedProductId,
                                    defaultQuantity: value.defaultQuantity,
                                  );
                                }),
                                icon: Icon(value.active ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              ),
                              IconButton(
                                onPressed: () => setD(() => values.removeAt(index)),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(
                onPressed: name.text.trim().isEmpty || values.where((e) => e.active).isEmpty
                    ? null
                    : () => Navigator.pop(
                          dialogContext,
                          KomandaOptionCatalog(
                            id: current?.id ?? 'local_${DateTime.now().microsecondsSinceEpoch}',
                            name: name.text.trim(),
                            slug: current?.slug ?? '',
                            active: active,
                            sortOrder: current?.sortOrder ?? 0,
                            values: values.asMap().entries.map((e) {
                              final v = e.value;
                              return KomandaOptionCatalogValue(
                                id: v.id,
                                label: v.label,
                                active: v.active,
                                sortOrder: e.key,
                                extraPrice: v.extraPrice,
                                complementId: v.complementId,
                                linkedProductId: v.linkedProductId,
                                defaultQuantity: v.defaultQuantity,
                              );
                            }).toList(),
                          ),
                        ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    name.dispose();
    option.dispose();
    if (result != null && context.mounted) {
      context.read<KomandaBloc>().add(KomandaOptionCatalogSaved(result));
    }
  }

  Future<void> _delete(BuildContext context, KomandaOptionCatalog catalog) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar configuración'),
        content: Text('¿Eliminar “${catalog.name}”? Los productos que la usen dejarán de tener esa lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<KomandaBloc>().add(KomandaOptionCatalogDeleted(catalog.id));
    }
  }
}
