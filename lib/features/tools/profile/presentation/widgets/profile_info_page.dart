import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ProfileInfoPage extends StatelessWidget {
  const ProfileInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('userBox');

    final nombre = box.get('nombre', defaultValue: '').toString().trim();
    final apellido = box.get('apellido', defaultValue: '').toString().trim();
    final correo = box.get('correo', defaultValue: '').toString().trim();

    final fullName = '$nombre $apellido'.trim();
    final displayName = fullName.isEmpty ? 'Usuario sin nombre' : fullName;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Información personal'),
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 18 : 28),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outline.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: isMobile ? 42 : 52,
                    backgroundColor: scheme.primary,
                    child: Text(
                      _initials(nombre, apellido),
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: isMobile ? 24 : 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    correo.isEmpty ? 'Correo no disponible' : correo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.62),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _InfoTile(
                    icon: Icons.person_rounded,
                    title: 'Nombre',
                    value: displayName,
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.email_rounded,
                    title: 'Correo electrónico',
                    value: correo.isEmpty ? 'No disponible' : correo,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String nombre, String apellido) {
    final n = nombre.trim().isNotEmpty ? nombre.trim()[0] : '';
    final a = apellido.trim().isNotEmpty ? apellido.trim()[0] : '';

    final result = '$n$a'.trim().toUpperCase();

    return result.isEmpty ? 'U' : result;
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.primary.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: scheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.60),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}