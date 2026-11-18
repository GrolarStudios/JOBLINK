import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/komanda_theme.dart';
import '../../data/datasources/komanda_remote_datasource.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';

/// Los cambios se guardan en la API; nunca se muestra éxito si falla el servidor.
class KomandaKitchenSettingsPage extends StatefulWidget {
  final KomandaRemoteDataSource remote;
  const KomandaKitchenSettingsPage({super.key, required this.remote});
  @override
  State<KomandaKitchenSettingsPage> createState() => _KomandaKitchenSettingsPageState();
}

class _KomandaKitchenSettingsPageState extends State<KomandaKitchenSettingsPage> {
  late Future<List<Map<String, dynamic>>> _stations;
  @override
  void initState() { super.initState(); _reload(); }
  void _reload() { _stations = widget.remote.getKitchenStations(); }

  Future<void> _edit([Map<String, dynamic>? station]) async {
    final state = context.read<KomandaBloc>().state;
    final name = TextEditingController(text: '${station?['name'] ?? ''}');
    final existingCategories = (station?['categoryNames'] as List? ?? const []).map((e) => '$e').toSet();
    final existingProducts = (station?['productIds'] as List? ?? const []).map((e) => '$e').toSet();
    final categories = <String>{...existingCategories};
    final products = <String>{...existingProducts};
    var active = station == null || station['active'] == true || station['active'] == 1 || station['active'] == '1';
    final id = station == null ? null : '${station['id']}';
    final shouldSave = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, update) => AlertDialog(
        title: Text(id == null ? 'Nuevo puesto de cocina' : 'Editar puesto'),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre del puesto', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Puesto activo'), value: active, onChanged: (v) => update(() => active = v)),
            const Text('Categorías', style: TextStyle(fontWeight: FontWeight.w900)),
            ...state.categories.where((c) => c.active).map((c) => CheckboxListTile(
              dense: true, contentPadding: EdgeInsets.zero, title: Text(c.name),
              value: categories.contains(c.name.toLowerCase()),
              onChanged: (v) => update(() { if (v == true) { categories.add(c.name.toLowerCase()); } else { categories.remove(c.name.toLowerCase()); } }),
            )),
            const Text('Productos específicos', style: TextStyle(fontWeight: FontWeight.w900)),
            ...state.products.map((product) => CheckboxListTile(
              dense: true, contentPadding: EdgeInsets.zero, title: Text(product.name), subtitle: Text(product.category),
              value: products.contains(product.id),
              onChanged: (v) => update(() { if (v == true) { products.add(product.id); } else { products.remove(product.id); } }),
            )),
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () { if (name.text.trim().isNotEmpty) Navigator.pop(dialogContext, true); }, child: const Text('Guardar')),
        ],
      ),
    ));
    if (shouldSave != true || !mounted) { name.dispose(); return; }
    try {
      await widget.remote.saveKitchenStation(id, {
        'name': name.text.trim(), 'active': active ? 1 : 0,
        'categoryNames': categories.toList(), 'productIds': products.toList(),
      });
      if (mounted) { setState(_reload); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puesto guardado correctamente.'))); }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar el puesto: $error')));
    } finally { name.dispose(); }
  }

  Future<void> _remove(Map<String, dynamic> station) async {
    final id = '${station['id']}';
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar puesto definitivamente'), content: Text('Se eliminará ${station['name']} y sus asignaciones de categorías y productos. Esta acción no se puede deshacer.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar'))],
    ));
    if (confirmed != true || !mounted) return;
    try { await widget.remote.deleteKitchenStation(id); if (mounted) { setState(_reload); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puesto eliminado definitivamente.'))); } }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error'))); }
  }

  @override
  Widget build(BuildContext context) => KomandaPhoneFrame(child: Column(children: [
    const KomandaHeader(title: 'Configurar cocina', bell: false),
    Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity,
      child: FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Agregar puesto')))),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: _stations, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No se pudo cargar la configuración: ${snapshot.error}')));
      final stations = snapshot.data ?? const <Map<String, dynamic>>[];
      if (stations.isEmpty) return const Center(child: Text('No hay puestos configurados.'));
      return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), itemCount: stations.length,
        itemBuilder: (context, index) { final station = stations[index];
          return Card(child: ListTile(
            leading: const Icon(Icons.soup_kitchen_rounded, color: KomandaTheme.purple),
            title: Text('${station['name'] ?? 'Puesto'}', style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('Categorías: ${(station['categoryNames'] as List? ?? const []).length} · Productos: ${(station['productIds'] as List? ?? const []).length}'),
            onTap: () => _edit(station),
            trailing: IconButton(tooltip: 'Eliminar', onPressed: () => _remove(station), icon: const Icon(Icons.delete_outline)),
          ));
        });
    })),
  ]));
}
