import 'package:flutter/material.dart';

import '../../../../../../core/utils/colors/gs_colors.dart';
import 'provider_view_helper.dart';

class ProviderEditAuctionDialog {
  ProviderEditAuctionDialog._();

  static Future<bool> show({
    required BuildContext context,
    required Map<String, dynamic> row,
    required Future<void> Function(DateTime inicio, DateTime fin) onSave,
  }) async {
    DateTime? fechaInicio = DateTime.tryParse(row['fechaInicio']?.toString() ?? '');
    DateTime? fechaFin = DateTime.tryParse(row['fechaTermino']?.toString() ?? '');

    bool saved = false;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<DateTime?> pickDateTime(DateTime? initialValue) async {
              final now = DateTime.now();

              final selectedDate = await showDatePicker(
                context: context,
                initialDate: initialValue ?? now,
                firstDate: now.subtract(const Duration(days: 3650)),
                lastDate: now.add(const Duration(days: 3650)),
              );

              if (selectedDate == null) return null;

              final selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(initialValue ?? now),
              );

              if (selectedTime == null) return null;

              return DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
            }

            Future<void> save() async {
              if (fechaInicio == null || fechaFin == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecciona fecha inicial y final'),
                  ),
                );
                return;
              }

              if (!fechaFin!.isAfter(fechaInicio!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La fecha final debe ser mayor a la inicial'),
                  ),
                );
                return;
              }

              try {
                setLocalState(() {
                  isSaving = true;
                });

                await onSave(fechaInicio!, fechaFin!);

                saved = true;

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (!context.mounted) return;

                setLocalState(() {
                  isSaving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar: $e'),
                  ),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text('Editar ${row['folio']}'),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DateSelectorTile(
                      label: 'Inicio',
                      value: fechaInicio,
                      icon: Icons.calendar_month_outlined,
                      enabled: !isSaving,
                      onTap: () async {
                        final picked = await pickDateTime(fechaInicio);

                        if (picked != null) {
                          setLocalState(() {
                            fechaInicio = picked;

                            if (fechaFin != null &&
                                !fechaFin!.isAfter(fechaInicio!)) {
                              fechaFin = null;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _DateSelectorTile(
                      label: 'Fin',
                      value: fechaFin,
                      icon: Icons.event_available_outlined,
                      enabled: !isSaving,
                      onTap: () async {
                        final picked = await pickDateTime(fechaFin);

                        if (picked != null) {
                          setLocalState(() {
                            fechaFin = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    if (fechaInicio != null && fechaFin != null)
                      _ResultStatusBox(
                        fechaInicio: fechaInicio!,
                        fechaFin: fechaFin!,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GSColors.primaryLight,
                    foregroundColor: GSColors.onPrimaryLight,
                  ),
                  onPressed: isSaving ? null : save,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    return saved;
  }
}

class _DateSelectorTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _DateSelectorTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GSColors.primaryLight.withOpacity(0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: GSColors.primaryLight,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label: ${ProviderViewHelper.formatDateTimeLabel(value)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStatusBox extends StatelessWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;

  const _ResultStatusBox({
    required this.fechaInicio,
    required this.fechaFin,
  });

  @override
  Widget build(BuildContext context) {
    final status = ProviderViewHelper.getStatusByDate(fechaInicio, fechaFin);
    final color = ProviderViewHelper.statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Estatus resultante: $status',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
