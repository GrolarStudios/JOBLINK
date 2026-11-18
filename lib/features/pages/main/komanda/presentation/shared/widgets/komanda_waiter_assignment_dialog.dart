import 'package:flutter/material.dart';

import '../../../core/komanda_theme.dart';
import '../../../domain/entities/komanda_waiter.dart';

Future<KomandaWaiter?> showKomandaWaiterAssignmentDialog({
  required BuildContext context,
  required List<KomandaWaiter> waiters,
  String currentWaiterId = '',
}) async {
  KomandaWaiter? selected = waiters
      .where((waiter) => waiter.userId == currentWaiterId)
      .firstOrNull;

  return showDialog<KomandaWaiter>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: KomandaTheme.purple.withOpacity(.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: KomandaTheme.purple,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asignar mesero',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: KomandaTheme.text,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Selecciona quién dará seguimiento a este pedido.',
                                style: TextStyle(
                                  color: KomandaTheme.softText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KomandaTheme.purple.withOpacity(.12)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: KomandaTheme.purple, size: 20),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'El pedido no podrá imprimirse hasta tener un mesero asignado.',
                              style: TextStyle(
                                color: KomandaTheme.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: waiters.map((waiter) {
                            final isSelected = selected?.userId == waiter.userId;
                            final initial = waiter.name.trim().isEmpty
                                ? 'M'
                                : waiter.name.trim().substring(0, 1).toUpperCase();

                            return InkWell(
                              onTap: () => setLocal(() => selected = waiter),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 220,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? KomandaTheme.purple.withOpacity(.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? KomandaTheme.purple
                                        : KomandaTheme.border,
                                    width: isSelected ? 1.7 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isSelected
                                          ? KomandaTheme.purple
                                          : const Color(0xFFF0EFF7),
                                      foregroundColor: isSelected
                                          ? Colors.white
                                          : KomandaTheme.text,
                                      child: Text(
                                        initial,
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            waiter.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: KomandaTheme.text,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isSelected ? 'Seleccionado' : 'Disponible',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected
                                                  ? KomandaTheme.purple
                                                  : KomandaTheme.softText,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: KomandaTheme.purple,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: selected == null
                                ? null
                                : () => Navigator.pop(dialogContext, selected),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Asignar mesero'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

extension _FirstOrNullWaiterDialog<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
