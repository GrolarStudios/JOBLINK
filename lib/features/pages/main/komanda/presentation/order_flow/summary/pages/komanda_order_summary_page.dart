import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/komanda_waiter.dart';
import '../../../bloc/komanda_bloc.dart';
import '../../../bloc/komanda_event.dart';
import '../../../bloc/komanda_state.dart';
import '../../../shared/widgets/komanda_widgets.dart';
import '../../../shared/widgets/komanda_item_detail_view.dart';

class KomandaOrderSummaryPage extends StatefulWidget {
  const KomandaOrderSummaryPage({super.key});

  @override
  State<KomandaOrderSummaryPage> createState() => _KomandaOrderSummaryPageState();
}

class _KomandaOrderSummaryPageState extends State<KomandaOrderSummaryPage> {
  final notesController = TextEditingController();
  KomandaWaiter? selectedWaiter;

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KomandaBloc, KomandaState>(
      listenWhen: (previous, current) => previous.status == KomandaStatus.saving && current.status == KomandaStatus.ready,
      listener: (context, state) => Navigator.popUntil(context, (route) => route.isFirst),
      builder: (context, state) => KomandaPageShell(
        title: 'Resumen',
        children: [
          KCard(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Mesa y disponibilidad',style:TextStyle(fontWeight:FontWeight.w900)),
            const SizedBox(height:8),
            DropdownButtonFormField<String>(
              value: state.selectedTable.isEmpty?null:state.selectedTable,
              decoration: const InputDecoration(labelText:'Mesa disponible',border:OutlineInputBorder()),
              items: state.tables.where((t)=>t.active && (state.openOrderForTable(t.name)==null || t.name==state.selectedTable)).map((t)=>DropdownMenuItem(value:t.name,child:Text('${t.name} · Disponible'))).toList(),
              onChanged:(value){if(value!=null)context.read<KomandaBloc>().add(KomandaTableSelected(value));},
            ),
          ])),
          for (final item in state.cart.values)
            KCard(
              child: KomandaItemDetailView(
                item: item,
                showPrice: true,
              ),
            ),
          DropdownButtonFormField<KomandaWaiter>(
            value: selectedWaiter,
            decoration: const InputDecoration(labelText: 'Mesero disponible', helperText: 'Selecciona uno de los meseros activos', border: OutlineInputBorder()),
            items: state.activeWaiters.map((w) => DropdownMenuItem(value: w, child: Text(w.name))).toList(),
            onChanged: (value) => setState(() => selectedWaiter = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notas generales', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          KMetricCard(label: 'Total', value: money(state.cartTotal), icon: Icons.payments),
          KPrimaryButton(
            text: state.status == KomandaStatus.saving ? 'Guardando...' : 'Guardar pedido',
            onPressed: state.canSaveOrder && state.status != KomandaStatus.saving
                ? () => context.read<KomandaBloc>().add(KomandaOrderCreated(notes: notesController.text, waiter: selectedWaiter))
                : null,
          ),
        ],
      ),
    );
  }
}
