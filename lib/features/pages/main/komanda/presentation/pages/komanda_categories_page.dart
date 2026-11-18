import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/komanda_category.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';

class KomandaCategoriesPage extends StatefulWidget {
  const KomandaCategoriesPage({super.key});

  @override
  State<KomandaCategoriesPage> createState() => _KomandaCategoriesPageState();
}

class _KomandaCategoriesPageState extends State<KomandaCategoriesPage> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<KomandaBloc>().add(const KomandaRefreshed());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final query = _search.trim().toLowerCase();
        final categories = state.categories
            .where((item) => query.isEmpty || item.name.toLowerCase().contains(query))
            .toList();

        return KomandaPhoneFrame(
          child: Column(
            children: [
              const KomandaHeader(title: 'Categorías', subtitle: 'Catálogo del negocio y nombre para tickets'),
              KomandaSearchField(
                hintText: 'Buscar categoría',
                onChanged: (value) => setState(() => _search = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar categoría'),
                  ),
                ),
              ),
              Expanded(
                child: categories.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 150),
                          Center(child: Text('No hay categorías que coincidan.')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return KomandaCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                              subtitle: Text(
                                category.printPrefix.trim().isEmpty
                                    ? 'Ticket: usa el nombre del producto tal cual'
                                    : 'Prefijo en ticket: ${category.printPrefix}',
                              ),
                              trailing: Wrap(
                                children: [
                                  IconButton(onPressed: () => _edit(context, category), icon: const Icon(Icons.edit_outlined)),
                                  IconButton(onPressed: () => _delete(context, category), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, [KomandaCategory? current]) async {
    final nameController = TextEditingController(text: current?.name ?? '');
    final prefixController = TextEditingController(text: current?.printPrefix ?? '');
    var active = current?.active ?? true;

    final category = await showDialog<KomandaCategory>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: Text(current == null ? 'Nueva categoría' : 'Editar categoría'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prefixController,
                  decoration: const InputDecoration(
                    labelText: 'Prefijo para ticket',
                    hintText: 'Ej. Taco o Torta',
                    helperText: 'Ej.: producto “Blando” + prefijo “Taco” = “Taco Blando”.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activa'),
                  value: active,
                  onChanged: (v) => setD(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  KomandaCategory(
                    id: current?.id ?? 'local_${DateTime.now().microsecondsSinceEpoch}',
                    name: name,
                    printPrefix: prefixController.text.trim(),
                    active: active,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    prefixController.dispose();

    if (category != null && context.mounted) {
      context.read<KomandaBloc>().add(KomandaCategorySaved(category));
    }
  }

  Future<void> _delete(BuildContext context, KomandaCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar ${category.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<KomandaBloc>().add(KomandaCategoryDeleted(category.id));
    }
  }
}
