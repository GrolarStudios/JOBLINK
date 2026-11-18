import 'package:flutter/material.dart';

import '../../core/utils/komanda_money.dart';

import '../../data/datasources/komanda_remote_datasource.dart';
import '../../domain/entities/komanda_complement.dart';
import '../widgets/komanda_widgets.dart';

class KomandaComplementsAdminPage extends StatefulWidget {
  final KomandaRemoteDataSource remote;
  const KomandaComplementsAdminPage({super.key, required this.remote});

  @override
  State<KomandaComplementsAdminPage> createState() => _KomandaComplementsAdminPageState();
}

class _KomandaComplementsAdminPageState extends State<KomandaComplementsAdminPage> {
  bool loading = true;
  String search = '';
  String type = 'Todos';
  List<KomandaComplement> items = const [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final rows = await widget.remote.getComplements();
      items = rows.map((r) => KomandaComplement(
        id: (r['id'] ?? '').toString(),
        type: (r['type'] ?? '').toString(),
        name: (r['name'] ?? '').toString(),
        extraPrice: (r['extraPrice'] as num? ?? 0).toDouble(),
        active: r['active'] == true || r['active'] == 1,
      )).toList();
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final types = <String>{'Carne', 'Relleno', ...items.map((e) => e.type).where((t) => t.trim().isNotEmpty)}.toList()..sort((a,b) => a == 'Carne' ? -1 : b == 'Carne' ? 1 : a.compareTo(b));
    final q = search.trim().toLowerCase();
    final filtered = items.where((e) => (type == 'Todos' || e.type == type) && (q.isEmpty || e.name.toLowerCase().contains(q))).toList();
    return KomandaPhoneFrame(child: Column(children: [
      KomandaHeader(title: 'Complementos', subtitle: 'Administra los tipos de complementos', onRefresh: _load),
      KomandaSearchField(hintText: 'Buscar complemento...', onChanged: (v) => setState(() => search = v)),
      SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: ['Todos', ...types].map((v) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(v), selected: type == v, onSelected: (_) => setState(() => type = v)))).toList())),
      Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Nuevo complemento')))),
      Expanded(child: loading ? const Center(child: Text('Actualizando...', style: TextStyle(fontWeight: FontWeight.w800))) : ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,24), itemCount: filtered.length, itemBuilder: (_, i) { final item = filtered[i]; return KomandaCard(child: ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Icon(item.type == 'Carne' ? Icons.restaurant : Icons.rice_bowl_outlined)), title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${item.type}${item.extraPrice > 0 ? ' · +${komandaMoney(item.extraPrice)}' : ''}${item.active ? '' : ' · Inactivo'}'), trailing: Wrap(children: [IconButton(onPressed: () => _edit(item), icon: const Icon(Icons.edit_outlined)), IconButton(onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline, color: Colors.red))]))); })),
    ]));
  }

  Future<void> _edit([KomandaComplement? current]) async {
    final name = TextEditingController(text: current?.name ?? '');
    final newType = TextEditingController();
    final types = <String>{'Carne', 'Relleno', ...items.map((e) => e.type).where((t) => t.trim().isNotEmpty)}.toList();
    final price = TextEditingController(text: current == null ? '0' : current.extraPrice.toStringAsFixed(2));
    String selectedType = current?.type ?? 'Carne'; bool active = current?.active ?? true;
    final saved = await showDialog<Map<String,dynamic>>(context: context, builder: (d) => StatefulBuilder(builder: (_, setD) => AlertDialog(title: Text(current == null ? 'Nuevo complemento' : 'Editar complemento'), content: SizedBox(width: 460, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')), const SizedBox(height: 10), DropdownButtonFormField<String>(initialValue: types.contains(selectedType) ? selectedType : types.first, items: types.map((t) => DropdownMenuItem(value:t,child:Text(t))).toList(), onChanged: (v)=>setD(()=>selectedType=v??selectedType), decoration: const InputDecoration(labelText:'Tipo de complemento')), const SizedBox(height:10), TextField(controller: newType, decoration: const InputDecoration(labelText: 'O escribe un tipo nuevo (opcional)', hintText: 'Ej. Salsa, Guarnición')), const SizedBox(height:10), TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal:true), decoration: const InputDecoration(labelText:'Precio extra',prefixText:'\$ ')), SwitchListTile(value: active, onChanged:(v)=>setD(()=>active=v), title: const Text('Activo'))])), actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancelar')), FilledButton(onPressed:()=>Navigator.pop(d, {'type':newType.text.trim().isEmpty ? selectedType : newType.text.trim(),'name':name.text.trim(),'extraPrice':double.tryParse(price.text.replaceAll(',','.'))??0,'active':active?1:0}), child:const Text('Guardar'))])));
    name.dispose(); price.dispose(); newType.dispose(); if (saved == null || saved['name'].toString().isEmpty) return;
    if (current == null) { await widget.remote.createComplement(saved); } else { await widget.remote.updateComplement(current.id, saved); }
    await _load();
  }

  Future<void> _delete(KomandaComplement item) async {
    final ok = await showDialog<bool>(context: context, builder:(d)=>AlertDialog(title:const Text('Eliminar complemento'),content:Text('¿Eliminar ${item.name}?'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Eliminar'))]));
    if (ok == true) { await widget.remote.deleteComplement(item.id); await _load(); }
  }
}
