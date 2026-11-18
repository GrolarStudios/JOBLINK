import 'package:flutter/material.dart';

import '../../core/komanda_theme.dart';
import '../../data/datasources/komanda_remote_datasource.dart';
import '../../domain/entities/komanda_session.dart';
import '../widgets/komanda_widgets.dart';

class KomandaProfilePage extends StatefulWidget {
  final KomandaSession session;
  final KomandaRemoteDataSource remote;
  final Future<void> Function(KomandaSession session) onSessionUpdated;
  final Future<void> Function() onLogout;

  const KomandaProfilePage({
    super.key,
    required this.session,
    required this.remote,
    required this.onSessionUpdated,
    required this.onLogout,
  });

  @override
  State<KomandaProfilePage> createState() => _KomandaProfilePageState();
}

class _KomandaProfilePageState extends State<KomandaProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _usernameController = TextEditingController(text: widget.session.username);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.remote.getMyProfile();
      if (!mounted) return;
      _nameController.text =
          (profile['name'] ?? widget.session.name).toString();
      _usernameController.text =
          (profile['username'] ?? widget.session.username).toString();
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KomandaPhoneFrame(
      child: Column(
        children: [
          const KomandaHeader(
            title: 'Mi perfil',
            subtitle: 'Cuenta y seguridad',
          ),
          Expanded(
            child: _loading
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      KomandaCard(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundColor:
                                  KomandaTheme.purple.withOpacity(.12),
                              child: Text(
                                _initials(_nameController.text),
                                style: const TextStyle(
                                  color: KomandaTheme.purple,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _nameController.text.trim().isEmpty
                                  ? widget.session.username
                                  : _nameController.text.trim(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_roleLabel(widget.session.role)} · ${widget.session.restaurantName}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: KomandaTheme.softText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      KomandaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Datos de usuario',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de usuario',
                                prefixIcon:
                                    Icon(Icons.alternate_email_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      KomandaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cambiar contraseña',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Déjala vacía si solo deseas actualizar tus datos.',
                              style: TextStyle(
                                color: KomandaTheme.softText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: _hideCurrentPassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña actual',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() {
                                    _hideCurrentPassword =
                                        !_hideCurrentPassword;
                                  }),
                                  icon: Icon(
                                    _hideCurrentPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPasswordController,
                              obscureText: _hideNewPassword,
                              decoration: InputDecoration(
                                labelText: 'Nueva contraseña',
                                prefixIcon: const Icon(Icons.key_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() {
                                    _hideNewPassword = !_hideNewPassword;
                                  }),
                                  icon: Icon(
                                    _hideNewPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _hideConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon:
                                    const Icon(Icons.verified_user_outlined),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() {
                                    _hideConfirmPassword =
                                        !_hideConfirmPassword;
                                  }),
                                  icon: Icon(
                                    _hideConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.shrink()
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Actualizando...' : 'Guardar cambios',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: _saving ? null : _confirmLogout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmation = _confirmPasswordController.text;

    if (name.isEmpty || username.isEmpty) {
      _showMessage('Captura tu nombre y usuario.');
      return;
    }

    if (newPassword.isNotEmpty) {
      if (currentPassword.isEmpty) {
        _showMessage('Captura tu contraseña actual.');
        return;
      }
      if (newPassword.length < 6) {
        _showMessage('La nueva contraseña debe tener al menos 6 caracteres.');
        return;
      }
      if (newPassword != confirmation) {
        _showMessage('La confirmación de la contraseña no coincide.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await widget.remote.updateMyProfile({
        'name': name,
        'username': username,
        if (newPassword.isNotEmpty) ...{
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      });

      final session = widget.session.copyWith(
        name: (updated['name'] ?? name).toString(),
        username: (updated['username'] ?? username).toString(),
      );

      await widget.onSessionUpdated(session);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Tus datos se actualizaron correctamente.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas salir de Komanda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.onLogout();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _roleLabel(String role) => switch (role) {
        'admin' => 'Administrador',
        'waiter' => 'Mesero',
        'chef' => 'Chef',
        'cashier' => 'Cajero',
        _ => role,
      };
}
