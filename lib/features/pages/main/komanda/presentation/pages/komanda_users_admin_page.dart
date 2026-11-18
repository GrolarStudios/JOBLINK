import 'package:flutter/material.dart';

import '../../data/datasources/komanda_remote_datasource.dart';
import '../widgets/komanda_widgets.dart';

class KomandaUsersAdminPage extends StatefulWidget {
  final KomandaRemoteDataSource remote;
  const KomandaUsersAdminPage({super.key, required this.remote});

  @override
  State<KomandaUsersAdminPage> createState() => _KomandaUsersAdminPageState();
}

class _KomandaUsersAdminPageState extends State<KomandaUsersAdminPage> {
  bool loading = true;
  String search = '';
  String? error;
  List<Map<String, dynamic>> users = const [];
  int page = 0;
  static const pageSize = 50;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      users = await widget.remote.getUsers();
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = search.trim().toLowerCase();
    final filtered = users.where((u) {
      return q.isEmpty ||
          (u['name'] ?? '').toString().toLowerCase().contains(q) ||
          (u['username'] ?? '').toString().toLowerCase().contains(q) ||
          (u['role'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    final pages=(filtered.length/pageSize).ceil().clamp(1,999999); if(page>=pages) page=pages-1; final visible=filtered.skip(page*pageSize).take(pageSize).toList();

    return KomandaPhoneFrame(
      child: Column(
        children: [
          const KomandaHeader(title: 'Usuarios y perfiles', subtitle: 'Personal del restaurante'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: KomandaSearchField(hintText: 'Buscar usuario o perfil', onChanged: (v) => setState(() => search = v))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: () => _edit(), icon: const Icon(Icons.person_add_alt_1_rounded)),
            ]),
          ),
          if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: Colors.red))),
          Expanded(
            child: loading
                ? const Center(child: Text('Actualizando...', style: TextStyle(fontWeight: FontWeight.w800)))
                : filtered.isEmpty
                        ? ListView(children: const [SizedBox(height: 140), Center(child: Text('No hay usuarios registrados.'))])
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: visible.length,
                            itemBuilder: (_, i) {
                              final u = visible[i];
                              return KomandaCard(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(child: Icon(_roleIcon((u['role'] ?? '').toString()))),
                                  title: Text((u['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                                  subtitle: Text('${u['username']} · ${_roleLabel((u['role'] ?? '').toString())}${(u['active'] == true || u['active'] == 1) ? '' : ' · Inactivo'}'),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) => v == 'edit' ? _edit(u) : _delete(u),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          if(filtered.length>pageSize) _pager(page,pages),
        ],
      ),
    );
  }

  Widget _pager(int current,int total)=>Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:current>0?()=>setState(()=>page--):null,icon:const Icon(Icons.chevron_left)),Text('Página ${current+1} de $total · 50 por página',style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:current+1<total?()=>setState(()=>page++):null,icon:const Icon(Icons.chevron_right))]);

  Future<void> _edit([Map<String, dynamic>? user]) async {
    final name = TextEditingController(text: (user?['name'] ?? '').toString());
    final username = TextEditingController(text: (user?['username'] ?? '').toString());
    final password = TextEditingController();
    String role = (user?['role'] ?? 'order_taker').toString();
    bool active = user == null || user['active'] == true || user['active'] == 1;

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (d) => StatefulBuilder(builder: (_, setLocal) => AlertDialog(
        title: Text(user == null ? 'Agregar usuario' : 'Editar usuario'),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre completo')),
          TextField(controller: username, enabled: user == null, decoration: const InputDecoration(labelText: 'Usuario')),
          TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: user == null ? 'Contraseña' : 'Nueva contraseña (opcional)')),
          DropdownButtonFormField<String>(
            value: role,
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Administrador total')),
              DropdownMenuItem(value: 'order_taker', child: Text('Nuevo pedido')),
              DropdownMenuItem(value: 'chef', child: Text('Cocina')),
            ],
            onChanged: (v) => setLocal(() => role = v ?? role),
            decoration: const InputDecoration(labelText: 'Perfil'),
          ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Usuario activo'), value: active, onChanged: (v) => setLocal(() => active = v)),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (name.text.trim().isEmpty || (user == null && (username.text.trim().isEmpty || password.text.isEmpty))) return;
            Navigator.pop(d, {'name': name.text.trim(), 'username': username.text.trim(), 'password': password.text, 'role': role, 'active': active ? 1 : 0});
          }, child: const Text('Guardar')),
        ],
      )),
    );
    name.dispose(); username.dispose(); password.dispose();
    if (data == null) return;
    try {
      if (user == null) {
        await widget.remote.createUser(data);
      } else {
        await widget.remote.updateUser((user['id'] ?? '').toString(), data);
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
      title: const Text('Eliminar usuario'),
      content: Text('¿Eliminar a ${(user['name'] ?? '').toString()}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar'))],
    ));
    if (ok != true) return;
    try { await widget.remote.deleteUser((user['id'] ?? '').toString()); await _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  String _roleLabel(String role) {
    if (role == 'admin') return 'Administrador total';
    if (role == 'order_taker') return 'Nuevo pedido';
    if (role == 'chef') return 'Cocina';
    return role;
  }

  IconData _roleIcon(String role) {
    if (role == 'admin') return Icons.admin_panel_settings_rounded;
    if (role == 'order_taker') return Icons.add_shopping_cart_rounded;
    if (role == 'chef') return Icons.soup_kitchen_rounded;
    return Icons.person_rounded;
  }
}
