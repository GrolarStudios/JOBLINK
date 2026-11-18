import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/waiter_call.dart';
import '../../../domain/entities/komanda_order.dart';
import '../../bloc/komanda_bloc.dart';
import '../../bloc/komanda_event.dart';
import '../../bloc/komanda_state.dart';
import '../../shared/widgets/komanda_widgets.dart';

class KomandaWaiterCallsPage extends StatefulWidget {
  const KomandaWaiterCallsPage({super.key});
  @override
  State<KomandaWaiterCallsPage> createState() => _KomandaWaiterCallsPageState();
}

class _KomandaWaiterCallsPageState extends State<KomandaWaiterCallsPage> {
  String statusFilter = 'Pendientes';
  String typeFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final calls = state.waiterCalls.where((call) {
          final statusMatches = statusFilter == 'Todos' ||
              (statusFilter == 'Pendientes' && call.status == WaiterCallStatus.pending) ||
              (statusFilter == 'Historial' && call.status == WaiterCallStatus.done);
          final typeMatches = typeFilter == 'Todos' ||
              (typeFilter == 'Llamados' && call.type == WaiterCallType.call) ||
              (typeFilter == 'Mensajes' && call.type == WaiterCallType.message);
          return statusMatches && typeMatches;
        }).toList();

        return KomandaPageShell(
          title: 'Llamados del mesero',
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openCreateCall(context, state),
            child: const Icon(Icons.add),
          ),
          children: [
            KMetricCard(label: 'Pendientes', value: '${state.pendingCalls}', icon: Icons.notifications_active),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Pendientes', 'Historial', 'Todos']
                  .map((value) => ChoiceChip(
                        label: Text(value),
                        selected: statusFilter == value,
                        onSelected: (_) => setState(() => statusFilter = value),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Todos', 'Llamados', 'Mensajes']
                  .map((value) => FilterChip(
                        label: Text(value),
                        selected: typeFilter == value,
                        onSelected: (_) => setState(() => typeFilter = value),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (calls.isEmpty) const KCard(child: Text('No hay llamados que coincidan con los filtros.')),
            for (final call in calls)
              KCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      child: Icon(call.type == WaiterCallType.call ? Icons.notifications_none : Icons.message_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${call.table} · ${call.type == WaiterCallType.call ? 'Llamado' : 'Mensaje'}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(call.message),
                          Text('${call.status.label} · ${formatDate(call.createdAt)}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (call.status == WaiterCallStatus.pending)
                      IconButton(
                        tooltip: 'Marcar atendido',
                        onPressed: () => context.read<KomandaBloc>().add(KomandaWaiterCallCompleted(call.id)),
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openCreateCall(BuildContext context, KomandaState state) async {
    final tableController = TextEditingController(text: state.selectedTable.isEmpty ? 'Mesa 1' : state.selectedTable);
    final messageController = TextEditingController(text: 'Cliente solicita atención');
    var type = WaiterCallType.call;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo llamado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tableController, decoration: const InputDecoration(labelText: 'Mesa')),
              const SizedBox(height: 10),
              DropdownButtonFormField<WaiterCallType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: WaiterCallType.call, child: Text('Llamado')),
                  DropdownMenuItem(value: WaiterCallType.message, child: Text('Mensaje')),
                ],
                onChanged: (value) => setDialogState(() => type = value ?? WaiterCallType.call),
              ),
              const SizedBox(height: 10),
              TextField(controller: messageController, maxLines: 3, decoration: const InputDecoration(labelText: 'Mensaje')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                context.read<KomandaBloc>().add(KomandaWaiterCallCreated(
                      table: tableController.text,
                      message: messageController.text,
                      type: type,
                    ));
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    tableController.dispose();
    messageController.dispose();
  }
}
