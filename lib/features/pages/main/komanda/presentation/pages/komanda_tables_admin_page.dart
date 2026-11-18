import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/komanda_table.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';

class KomandaTablesAdminPage extends StatefulWidget {
  const KomandaTablesAdminPage({super.key});

  @override
  State<KomandaTablesAdminPage> createState() => _KomandaTablesAdminPageState();
}

class _KomandaTablesAdminPageState extends State<KomandaTablesAdminPage> {
  String _search = '';
  int _page=0; static const _pageSize=50;

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
        final tables = state.tables.where((table) {
          return query.isEmpty ||
              table.name.toLowerCase().contains(query) ||
              '${table.capacity}'.contains(query);
        }).toList();

        final pages=(tables.length/_pageSize).ceil().clamp(1,999999); if(_page>=pages)_page=pages-1; final visible=tables.skip(_page*_pageSize).take(_pageSize).toList();
        return KomandaPhoneFrame(
          child: Column(
            children: [
              const KomandaHeader(title: 'Administrar mesas', subtitle: 'Mesas disponibles en el negocio'),
              KomandaSearchField(
                hintText: 'Buscar mesa o capacidad',
                onChanged: (value) => setState(() => _search = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar mesa'),
                  ),
                ),
              ),
              Expanded(
                child: tables.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [SizedBox(height: 150), Center(child: Text('No hay mesas que coincidan.'))],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final table = visible[index];
                            return KomandaCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(child: Icon(Icons.table_restaurant_outlined)),
                                title: Text(table.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                subtitle: Text('Capacidad: ${table.capacity} personas'),
                                trailing: Wrap(
                                  children: [
                                    IconButton(onPressed: () => _edit(context, table), icon: const Icon(Icons.edit_outlined)),
                                    IconButton(onPressed: () => _delete(context, table), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
              if(tables.length>_pageSize) Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:_page>0?()=>setState(()=>_page--):null,icon:const Icon(Icons.chevron_left)),Text('Página ${_page+1} de $pages · 50 por página',style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:_page+1<pages?()=>setState(()=>_page++):null,icon:const Icon(Icons.chevron_right))]),
            ],
          ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, [KomandaTable? current]) async {
    final name = TextEditingController(text: current?.name ?? '');
    final capacity = TextEditingController(text: '${current?.capacity ?? 4}');
    final result = await showDialog<KomandaTable>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(current == null ? 'Nueva mesa' : 'Editar mesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre, por ejemplo Terraza 1')),
            TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacidad')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final value = name.text.trim();
              final people = int.tryParse(capacity.text) ?? 0;
              if (value.isEmpty || people <= 0) return;
              Navigator.pop(
                dialogContext,
                KomandaTable(
                  id: current?.id ?? 'local_${DateTime.now().microsecondsSinceEpoch}',
                  name: value,
                  capacity: people,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    name.dispose();
    capacity.dispose();
    if (result != null && context.mounted) {
      context.read<KomandaBloc>().add(KomandaTableSaved(result));
    }
  }

  Future<void> _delete(BuildContext context, KomandaTable table) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar mesa'),
        content: Text('¿Eliminar ${table.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<KomandaBloc>().add(KomandaTableDeleted(table.id));
    }
  }
}
