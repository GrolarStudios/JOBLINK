import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/komanda_waiter.dart';
import '../../bloc/komanda_bloc.dart';
import '../../bloc/komanda_event.dart';
import '../../bloc/komanda_state.dart';
import '../../widgets/komanda_widgets.dart';

class KomandaWaitersPage extends StatefulWidget {
  const KomandaWaitersPage({super.key});

  @override
  State<KomandaWaitersPage> createState() => _KomandaWaitersPageState();
}

class _KomandaWaitersPageState extends State<KomandaWaitersPage> {
  final Map<String, bool> _optimistic = <String, bool>{};
  final Set<String> _saving = <String>{};
  String _search = '';
  int _page=0; static const _pageSize=50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<KomandaBloc>().add(const KomandaRefreshed());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KomandaBloc, KomandaState>(
      listener: (context, state) {
        if (state.status != KomandaStatus.saving && _saving.isNotEmpty) {
          setState(() {
            _saving.clear();
            _optimistic.clear();
          });
        }
      },
      builder: (context, state) {
        final query = _search.trim().toLowerCase();
        final waiters = state.waiters.where((waiter) {
          return query.isEmpty ||
              waiter.name.toLowerCase().contains(query) ||
              waiter.username.toLowerCase().contains(query) ||
              waiter.userId.toLowerCase().contains(query);
        }).toList();

        final pages=(waiters.length/_pageSize).ceil().clamp(1,999999); if(_page>=pages)_page=pages-1; final visible=waiters.skip(_page*_pageSize).take(_pageSize).toList();
        return KomandaPhoneFrame(
          child: Column(
            children: [
              const KomandaHeader(
                title: 'Administración de meseros',
                subtitle: 'Usuarios del restaurante con perfil Mesero',
              ),
              KomandaSearchField(
                hintText: 'Buscar mesero o usuario',
                onChanged: (value) => setState(() => _search = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openWaiterDialog(context),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Crear nuevo mesero'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: waiters.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay usuarios con perfil Mesero.\nCrea uno para generar automáticamente su cuenta y su registro operativo.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final waiter = visible[index];
                            final active =
                                _optimistic[waiter.id] ?? waiter.active;

                            return KomandaCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Text(
                                    waiter.name.isEmpty
                                        ? 'M'
                                        : waiter.name[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  waiter.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  '${waiter.username.isEmpty ? 'Sin usuario vinculado' : '@${waiter.username}'}\n'
                                  '${active ? 'Activo' : 'Inactivo'} · Perfil: Mesero\nID mesero: ${waiter.id} · Usuario ID: ${waiter.userId}',
                                ),
                                isThreeLine: true,
                                onTap: () => _openWaiterDialog(
                                  context,
                                  waiter: waiter,
                                ),
                                trailing: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (_saving.contains(waiter.id))
                                      const Text(
                                        'Actualizando...',
                                        style: TextStyle(fontWeight: FontWeight.w800),
                                      )
                                    else
                                      Switch(
                                        value: active,
                                        onChanged: (value) =>
                                            _toggle(context, waiter, value),
                                      ),
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: () => _openWaiterDialog(
                                        context,
                                        waiter: waiter,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: () => _delete(context, waiter),
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
              ),
              if(waiters.length>_pageSize) Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:_page>0?()=>setState(()=>_page--):null,icon:const Icon(Icons.chevron_left)),Text('Página ${_page+1} de $pages · 50 por página',style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:_page+1<pages?()=>setState(()=>_page++):null,icon:const Icon(Icons.chevron_right))]),
            ],
          ),
        );
      },
    );
  }

  void _toggle(
    BuildContext context,
    KomandaWaiter waiter,
    bool value,
  ) {
    setState(() {
      _optimistic[waiter.id] = value;
      _saving.add(waiter.id);
    });

    context.read<KomandaBloc>().add(
          KomandaWaiterSaved(
            waiter.copyWith(
              active: value,
              password: '',
            ),
          ),
        );
  }

  Future<void> _openWaiterDialog(
    BuildContext context, {
    KomandaWaiter? waiter,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: waiter?.name ?? '');
    final usernameController =
        TextEditingController(text: waiter?.username ?? '');
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    var active = waiter?.active ?? true;
    var obscurePassword = true;
    var obscureConfirm = true;

    final result = await showDialog<KomandaWaiter>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                waiter == null ? 'Crear mesero' : 'Editar mesero',
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Escribe el nombre del mesero'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: usernameController,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: 'Usuario para iniciar sesión',
                            hintText: 'Ejemplo: mesero.juan',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'Escribe un nombre de usuario';
                            if (text.length < 3) return 'Usa al menos 3 caracteres';
                            if (text.contains(' ')) return 'El usuario no debe llevar espacios';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: waiter == null
                                ? 'Contraseña'
                                : 'Nueva contraseña (opcional)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setDialogState(
                                () => obscurePassword = !obscurePassword,
                              ),
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final text = value ?? '';
                            if (waiter == null && text.isEmpty) {
                              return 'Escribe una contraseña';
                            }
                            if (text.isNotEmpty && text.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: waiter == null
                                ? 'Confirmar contraseña'
                                : 'Confirmar nueva contraseña',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              onPressed: () => setDialogState(
                                () => obscureConfirm = !obscureConfirm,
                              ),
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (passwordController.text.isNotEmpty &&
                                value != passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Mesero activo'),
                          subtitle: const Text(
                            'También controla si el usuario puede iniciar sesión.',
                          ),
                          value: active,
                          onChanged: (value) =>
                              setDialogState(() => active = value),
                        ),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.verified_user_outlined),
                          title: Text('Perfil asignado automáticamente'),
                          subtitle: Text('Mesero (waiter)'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;

                    Navigator.pop(
                      dialogContext,
                      KomandaWaiter(
                        id: waiter?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        userId: waiter?.userId ?? '',
                        name: nameController.text.trim(),
                        username: usernameController.text.trim(),
                        password: passwordController.text,
                        active: active,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar mesero'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    if (result != null && context.mounted) {
      context.read<KomandaBloc>().add(
            KomandaWaiterSaved(result),
          );
    }
  }

  Future<void> _delete(
    BuildContext context,
    KomandaWaiter waiter,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar mesero'),
        content: Text(
          '¿Eliminar a ${waiter.name}? También se desactivará su usuario de acceso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<KomandaBloc>().add(
            KomandaWaiterDeleted(waiter.id),
          );
    }
  }
}
