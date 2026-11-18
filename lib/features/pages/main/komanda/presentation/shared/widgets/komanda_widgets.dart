import 'package:flutter/material.dart';

import '../../../core/utils/komanda_money.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/routes/route_names.dart';
import '../../../core/komanda_theme.dart';
import '../../bloc/komanda_bloc.dart';
import '../../bloc/komanda_event.dart';

class KomandaPageShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final List<Widget> actions;

  const KomandaPageShell({
    super.key,
    required this.title,
    required this.children,
    this.floatingActionButton,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KomandaTheme.bg,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => context.read<KomandaBloc>().add(const KomandaRefreshed()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        backgroundColor: KomandaTheme.card,
        foregroundColor: KomandaTheme.text,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (actions.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: actions,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final String route;
  const _MenuTile({required this.icon, required this.text, required this.route});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(text),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(context, route, (route) => route.isFirst);
        },
      );
}

class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const KCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: KomandaTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KomandaTheme.border),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: child,
      );
}

class KMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const KMetricCard({super.key, required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => KCard(
        child: Row(children: [
          CircleAvatar(backgroundColor: KomandaTheme.primary, foregroundColor: Colors.white, child: Icon(icon)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: KomandaTheme.softText))),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
      );
}

class KPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const KPrimaryButton({super.key, required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: KomandaTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onPressed,
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
}

class KStatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const KStatusChip({super.key, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

String money(double value) => komandaMoney(value);
String formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
