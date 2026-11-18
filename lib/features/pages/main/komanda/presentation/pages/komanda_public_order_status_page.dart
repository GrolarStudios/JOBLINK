import '../shared/widgets/komanda_touch_keyboard.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../core/printing/komanda_ticket_print_service.dart';
import '../../core/printing/komanda_kitchen_print_service.dart';
import '../../core/utils/komanda_order_sections.dart';
import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/komanda_product.dart';
import '../shared/widgets/komanda_payment_dialog.dart';
import '../shared/widgets/komanda_order_product_picker.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';
import 'komanda_detail_page.dart';

class KomandaPublicOrderStatusPage extends StatefulWidget {
  const KomandaPublicOrderStatusPage({super.key});

  @override
  State<KomandaPublicOrderStatusPage> createState() =>
      _KomandaPublicOrderStatusPageState();
}

class _KomandaPublicOrderStatusPageState
    extends State<KomandaPublicOrderStatusPage> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  String _dateScope = 'Hoy';
  String _typeScope = 'Todos';
  String _statusScope = 'Activos';
  DateTime? _selectedDate;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _createManualTicket() async {
    final amount = TextEditingController();
    final received = TextEditingController();
    bool saving = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, refresh) {
        final total = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
        final cash = double.tryParse(received.text.replaceAll(',', '.')) ?? 0;
        final change = (cash - total).clamp(0, double.infinity).toDouble();
        const accent = Color(0xFFEA6A20);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accent.withOpacity(.10), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.receipt_long_rounded, color: accent, size: 26)),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nuevo ticket manual', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Registro de cobro', style: TextStyle(fontSize: 12, color: Color(0xFF717784))),
                  ])),
                  IconButton(tooltip: 'Cerrar', onPressed: saving ? null : () => Navigator.pop(dialogContext), icon: const Icon(Icons.close_rounded)),
                ]),
                const SizedBox(height: 20),
                const Text('IMPORTE DEL TICKET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8, color: Color(0xFF666D7A))),
                const SizedBox(height: 8),
                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(prefixText: '\$ ', hintText: '0.00', filled: true, fillColor: const Color(0xFFF7F8FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), suffixIcon: KomandaTouchKeyboard.button(dialogContext, amount, numeric: true, onChanged: (_) => refresh(() {}))),
                  onChanged: (_) => refresh(() {})),
                const SizedBox(height: 18),
                const Text('CANTIDAD RECIBIDA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8, color: Color(0xFF666D7A))),
                const SizedBox(height: 8),
                TextField(controller: received, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(prefixText: '\$ ', hintText: '0.00', filled: true, fillColor: const Color(0xFFF7F8FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), suffixIcon: KomandaTouchKeyboard.button(dialogContext, received, numeric: true, onChanged: (_) => refresh(() {}))),
                  onChanged: (_) => refresh(() {})),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF6F7F9), borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(color: Color(0xFF626976))), Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700))]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Recibí', style: TextStyle(color: Color(0xFF626976))), Text('\$${cash.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700))]),
                    const Divider(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Cambio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Text('\$${change.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: accent))]),
                  ]),
                ),
                if (total > 0 && cash < total) ...[
                  const SizedBox(height: 10),
                  const Text('La cantidad recibida debe cubrir el total.', style: TextStyle(color: Color(0xFFB42318), fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: saving || total <= 0 || cash < total ? null : () async {
                    refresh(() => saving = true);
                    try {
                      final bloc = context.read<KomandaBloc>();
                      final result = await bloc.saveOrder.repository.createManualTicket(total, cash);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      bloc.add(const KomandaRefreshed(showLoading: false));
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ticket guardado · Folio ${result['folio'] ?? ''}')));
                    } catch (error) {
                      if (dialogContext.mounted) {
                        refresh(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
                      }
                    }
                  },
                  icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(saving ? 'Guardando ticket...' : 'Guardar ticket', style: const TextStyle(fontWeight: FontWeight.w800)),
                )),
              ]),
            ),
          ),
        );
      },
    ));
    amount.dispose();
    received.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: BlocBuilder<KomandaBloc, KomandaState>(
          builder: (context, state) {
            final today = DateTime(_now.year, _now.month, _now.day);
            bool dateOk(KomandaOrder o) {
              final d=DateTime(o.createdAt.year,o.createdAt.month,o.createdAt.day);
              if (_dateScope=='Hoy') return d==today;
              if (_dateScope=='Anteriores') return d.isBefore(today);
              if (_dateScope=='Fecha' && _selectedDate!=null) return d==DateTime(_selectedDate!.year,_selectedDate!.month,_selectedDate!.day);
              return true;
            }
            bool typeOk(KomandaOrder o) {
              if (_typeScope=='Domicilio') return o.isDelivery;
              if (_typeScope=='Para llevar') return o.isTakeaway;
              if (_typeScope=='Aquí') return !o.isDelivery && !o.isTakeaway;
              return true;
            }
            final cancelled = state.orders.where((o) => o.status == KomandaOrderStatus.cancelled && dateOk(o) && typeOk(o)).toList()..sort((a,b) => b.createdAt.compareTo(a.createdAt));
            final active = state.orders
                .where((o) => o.status != KomandaOrderStatus.cancelled && dateOk(o) && typeOk(o))
                .toList();

            // En preparación se mantiene igual mientras el pedido todavía
            // no esté listo para el cliente.
            final preparing = active
                .where((o) =>
            !(o.isTakeaway || o.isDelivery) && (o.status == KomandaOrderStatus.pending ||
                o.status == KomandaOrderStatus.preparing))
                .toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

            // La preparación y el cobro son procesos independientes.
            // Un pedido preparado debe permanecer pendiente de entrega
            // aunque ya se haya pagado.
            final ready = active
                .where((o) =>
            ((o.isTakeaway || o.isDelivery) && !o.isPaid) ||
                (!(o.isTakeaway || o.isDelivery) && (o.status == KomandaOrderStatus.waiting ||
                o.status == KomandaOrderStatus.delivering)))
                .toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

            // ENTREGADOS depende del estado real de entrega, no de isPaid.
            // Así, al tocar "Entregar pedido" aparece aquí inmediatamente.
            final completed = active
                .where((o) =>
            ((o.isTakeaway || o.isDelivery) && o.isPaid) ||
                (o.status == KomandaOrderStatus.atTable ||
                o.status == KomandaOrderStatus.completed))
                .toList()
              ..sort((a, b) {
                final aEnd = a.deliveredAt ??
                    a.releasedAt ??
                    a.paidAt ??
                    a.readyAt ??
                    a.createdAt;
                final bEnd = b.deliveredAt ??
                    b.releasedAt ??
                    b.paidAt ??
                    b.readyAt ??
                    b.createdAt;
                return bEnd.compareTo(aEnd);
              });

            return Column(
              children: [
                _header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(children:[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _showFilters = !_showFilters),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: KomandaTheme.purple.withOpacity(.20)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.tune_rounded, size: 19, color: KomandaTheme.purple),
                              const SizedBox(width: 9),
                              Text(_showFilters ? 'Ocultar filtros' : 'Filtrar pedidos',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: KomandaTheme.text)),
                              const SizedBox(width: 12),
                              Icon(_showFilters ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 20, color: KomandaTheme.purple),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    if(_showFilters)...[
                      const SizedBox(height:8),
                      Wrap(spacing:8,runSpacing:8,children:['Todos','Hoy','Anteriores','Fecha'].map((v)=>ChoiceChip(label:Text(v),selected:_dateScope==v,onSelected:(_) async { if(v=='Fecha'){final d=await showDatePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime.now(),initialDate:_selectedDate??DateTime.now()); if(d==null)return; setState((){_selectedDate=d;_dateScope=v;});}else{setState(()=>_dateScope=v);}})).toList()),
                      const SizedBox(height:6),
                      Wrap(spacing:8,runSpacing:8,children:['Domicilio','Aquí','Para llevar'].map((v)=>ChoiceChip(label:Text(v),selected:_typeScope==v,onSelected:(_)=>setState(()=>_typeScope = _typeScope == v ? 'Todos' : v))).toList()),
                       const SizedBox(height: 8),
                       Align(alignment: Alignment.centerLeft, child: Text('Estado del pedido', style: TextStyle(fontWeight: FontWeight.w800, color: KomandaTheme.text))),
                       const SizedBox(height: 6),
                       Wrap(spacing: 8, runSpacing: 8, children: ['Activos', 'Todos', 'Preparación', 'Pendiente', 'Entregados', 'Cancelados'].map((v) => ChoiceChip(label: Text(v == 'Activos' ? 'Preparación y pendiente' : v), selected: _statusScope == v, onSelected: (_) => setState(() => _statusScope = v))).toList()),
                    ],
                  ]),
                ),
                                 Expanded(
                   child: Padding(
                     padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                     child: _StatusPanel(
                       title: _statusScope == 'Activos' ? 'PEDIDOS ACTIVOS' : _statusScope == 'Todos' ? 'TODOS LOS PEDIDOS' : _statusScope == 'Preparación' ? 'EN PREPARACIÓN' : _statusScope == 'Pendiente' ? 'PENDIENTE DE ENTREGA' : _statusScope == 'Cancelados' ? 'PEDIDOS CANCELADOS' : 'ENTREGADOS',
                       subtitle: _statusScope == 'Activos' ? 'PEDIDOS ACTIVOS' : _statusScope == 'Todos' ? 'Todos los estados del periodo seleccionado' : _statusScope == 'Preparación' ? 'Estamos preparando tu pedido' : _statusScope == 'Pendiente' ? 'Primero cobra y después entrega' : _statusScope == 'Cancelados' ? 'Historial de pedidos cancelados' : 'Pedidos entregados recientemente',
                       icon: _statusScope == 'Activos' ? Icons.pending_actions_rounded : _statusScope == 'Todos' ? Icons.list_alt_rounded : _statusScope == 'Preparación' ? Icons.restaurant_rounded : _statusScope == 'Pendiente' ? Icons.notifications_active_rounded : _statusScope == 'Cancelados' ? Icons.cancel_outlined : Icons.check_circle_rounded,
                       color: _statusScope == 'Preparación' ? const Color(0xFFC56A08) : _statusScope == 'Pendiente' ? const Color(0xFF2563EB) : _statusScope == 'Entregados' ? const Color(0xFF16A34A) : _statusScope == 'Cancelados' ? const Color(0xFFB91C1C) : KomandaTheme.purple,
                       orders: _statusScope == 'Activos' ? ([...preparing, ...ready]..sort((a,b) => b.createdAt.compareTo(a.createdAt))) : _statusScope == 'Todos' ? (active..sort((a,b) => b.createdAt.compareTo(a.createdAt))) : _statusScope == 'Preparación' ? preparing : _statusScope == 'Pendiente' ? ready : _statusScope == 'Cancelados' ? cancelled : completed,
                       products: state.products,
                       emphasize: _statusScope == 'Pendiente',
                        onAddTicket: _createManualTicket,
                     ),
                   ),
                 ),
const BottomNavMock(index: -1),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statusTab({
    required String label,
    required int count,
    required Color color,
  }) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 21,
                  minHeight: 21,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: color.withOpacity(.25),
                  ),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Regresar',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Estado pedidos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: KomandaTheme.text,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refrescar pedidos',
            onPressed: () => context.read<KomandaBloc>().add(KomandaRefreshed()),
            icon: const Icon(Icons.refresh_rounded),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_time(_now),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              Text(_date(_now),
                  style: const TextStyle(
                      color: KomandaTheme.softText,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _StatusPanel extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<KomandaOrder> orders;
  final List<KomandaProduct> products;
  final bool emphasize;
  final VoidCallback onAddTicket;

  const _StatusPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.orders,
    required this.products,
    required this.emphasize,
    required this.onAddTicket,
  });

  @override
  State<_StatusPanel> createState() => _StatusPanelState();
}

class _StatusPanelState extends State<_StatusPanel> {
  String get title=>widget.title; String get subtitle=>widget.subtitle; IconData get icon=>widget.icon; Color get color=>widget.color; List<KomandaProduct> get products=>widget.products; bool get emphasize=>widget.emphasize;
  int page = 0;
  static const pageSize = 50;
  @override
  Widget build(BuildContext context) {
    final pages=(widget.orders.length/pageSize).ceil().clamp(1,999999);
    if(page>=pages) page=pages-1;
    final visible=widget.orders.skip(page*pageSize).take(pageSize).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: widget.color.withOpacity(.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _panelHeader(),
          Expanded(
            child: widget.orders.isEmpty
                ? _emptyState()
                : GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 330,
                mainAxisExtent: 345,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: visible.length,
              itemBuilder: (context, index) =>
                  _OrderStatusCard(
                    order: visible[index],
                    color: (visible[index].isTakeaway || visible[index].isDelivery)
                        ? (visible[index].isPaid ? const Color(0xFF16A34A) : const Color(0xFF2563EB))
                        : visible[index].status == KomandaOrderStatus.pending || visible[index].status == KomandaOrderStatus.preparing
                        ? const Color(0xFFC56A08)
                        : visible[index].status == KomandaOrderStatus.waiting || visible[index].status == KomandaOrderStatus.delivering
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF16A34A),
                    emphasize: true,
                    onEdit: () => _editOrder(context, visible[index]),
                  ),
            ),
          ),
          if(widget.orders.length>pageSize) Padding(padding:const EdgeInsets.only(bottom:8),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:page>0?()=>setState(()=>page--):null,icon:const Icon(Icons.chevron_left)),Text('Página ${page+1} de $pages · 50 por página',style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:page+1<pages?()=>setState(()=>page++):null,icon:const Icon(Icons.chevron_right))])),
        ],
      ),
    );
  }

  Widget _panelHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(emphasize ? .13 : .075),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.color.withOpacity(.18)),
            ),
            child: Icon(icon, color: widget.color, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: emphasize ? 18 : 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KomandaTheme.softText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = MediaQuery.sizeOf(context).width < 560;
              return Tooltip(
                message: 'Agregar ticket manual',
                child: OutlinedButton.icon(
                  onPressed: widget.onAddTicket,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.color,
                    padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: 10),
                    minimumSize: const Size(40, 38),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: compact ? const SizedBox.shrink() : const Text('Agregar ticket'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 38),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${widget.orders.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_outlined, color: widget.color.withOpacity(.65)),
          ),
          const SizedBox(height: 10),
          Text(
            'Sin pedidos',
            style: TextStyle(
              color: widget.color.withOpacity(.72),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editOrder(BuildContext context, KomandaOrder order) async {
    final edited = await showDialog<KomandaOrder>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditOrderDialog(order: order, products: products),
    );
    if (edited == null || !context.mounted) return;
    final difference = (edited.total + edited.tipAmount) - order.paidAmount;
    context.read<KomandaBloc>().add(KomandaOrderEdited(order: edited));
    if (order.paidAmount > 0 && difference > 0.009 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido actualizado. Diferencia por cobrar: ${komandaMoney(difference)}')),
      );
    }
  }
}

class _OrderStatusCard extends StatelessWidget {
  final KomandaOrder order;
  final Color color;
  final bool emphasize;
  final VoidCallback onEdit;

  const _OrderStatusCard({
    required this.order,
    required this.color,
    required this.emphasize,
    required this.onEdit,
  });

  bool get _canMarkPrepared =>
      order.status == KomandaOrderStatus.pending ||
          order.status == KomandaOrderStatus.preparing;

  bool get _canDeliver =>
      order.status == KomandaOrderStatus.waiting ||
          order.status == KomandaOrderStatus.delivering;

  @override
  Widget build(BuildContext context) {
    final saving = context.select<KomandaBloc, bool>((bloc) => bloc.state.status == KomandaStatus.saving);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetail(context),
        child: Ink(
          decoration: BoxDecoration(
            color: emphasize ? color.withOpacity(.09) : const Color(0xFFFAFAFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: emphasize ? color.withOpacity(.32) : const Color(0xFFE9E9F1),
              width: emphasize ? 1.4 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Para aquí: mesa destacada antes del folio.
                if (!order.isDelivery && !order.isTakeaway && order.table.trim().isNotEmpty) ...[
                  Text('MESA ${order.table.trim()}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 29, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                ],
                // Folio en su propia fila: evita que se parta en móviles.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Folio #${order.shortFolio}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: color,
                          fontSize: 19,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (order.status != KomandaOrderStatus.cancelled && !order.isPaid)
                      PopupMenuButton<String>(
                        tooltip: 'Acciones del pedido',
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (action) { if (action == 'cancel') _cancelOrder(context); },
                        itemBuilder: (_) => const [PopupMenuItem(value: 'cancel', child: Text('Cancelar pedido'))],
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _statusChip(),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        order.isDelivery
                            ? Icons.delivery_dining_rounded
                            : order.isTakeaway
                            ? Icons.shopping_bag_outlined
                            : Icons.storefront_outlined,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.orderType.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.isDelivery && order.deliveryAddress.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: color.withOpacity(.85)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          order.deliveryAddress.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: KomandaTheme.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (!order.isDelivery && !order.isTakeaway) ...[
                  if (order.waiterName.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('Atiende: ${order.waiterName.trim()}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: color.withOpacity(.85)),
                    const SizedBox(width: 5),
                    Text(
                      _orderTimeLabel(order),
                      style: const TextStyle(
                        color: KomandaTheme.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Divider(height: 1, color: Color(0xFFECECF3)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _compactButton(
                        context,
                        icon: Icons.visibility_outlined,
                        label: 'Detalle',
                        onPressed: () => _openDetail(context),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _compactButton(
                        context,
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _compactButton(
                        context,
                        icon: Icons.print_outlined,
                        label: 'Imprimir',
                        onPressed: () => _printOrder(context),
                      ),
                    ),
                  ],
                ),
                if ((order.isTakeaway || order.isDelivery) && !order.isPaid) ...[
                  const SizedBox(height: 7),
                  SizedBox(width: double.infinity, height: 36,
                    child: FilledButton.icon(
                      onPressed: saving ? null : () => _charge(context),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Cobrar pedido', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
                if (!(order.isTakeaway || order.isDelivery) && (_canMarkPrepared || _canDeliver)) ...[
                  const SizedBox(height: 7),
                  SizedBox(width: double.infinity, height: 36, child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                    onPressed: saving ? null : () => _advanceStatus(context),
                    icon: saving
                        ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(_canDeliver ? Icons.delivery_dining_rounded : Icons.check_circle_outline_rounded, size: 18),
                    label: Text(saving ? 'Actualizando...' : (_canDeliver ? 'Entregar pedido' : 'Marcar preparado'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text('¿Cancelar el pedido #${order.shortFolio}? Se conservará en el historial de cancelaciones.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmar cancelación')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<KomandaBloc>().add(KomandaOrderStatusChanged(orderId: order.id, status: KomandaOrderStatus.cancelled));
    }
  }

  Future<void> _printOrder(BuildContext context) async {
    final config = context.read<KomandaBloc>().state.ticketConfig;
    final tortas = KomandaOrderSections.itemsFor(
      order.items,
      KomandaOrderSection.tortas,
    );
    final tacos = KomandaOrderSections.itemsFor(
      order.items,
      KomandaOrderSection.tacos,
    );

    final scope = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: KomandaTheme.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Imprimir pedido',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_rounded),
                ),
                title: const Text('Ticket cliente', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Tortas y Tacos separados por plato'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, false),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.restaurant_menu_rounded)),
                title: const Text('Ticket cocina', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Preparación con nombre cliente y letras grandes'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      ),
    );

    if (scope == null || !context.mounted) return;

    try {
      if (scope) {
        await KomandaKitchenPrintService.printOrder(
          order, config, restaurantId: context.read<KomandaBloc>().restaurantId);
      } else {
        await KomandaTicketPrintService.printOrder(
          order,
          config,
          scope: KomandaTicketPrintScope.all,
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo imprimir el pedido. Intenta nuevamente.'),
        ),
      );
    }
  }

  Widget _statusChip() {
    String label;
    IconData icon;
    if (order.isTakeaway || order.isDelivery) {
      label = order.isPaid ? 'ENTREGADO' : 'PENDIENTE DE PAGO';
      icon = order.isPaid ? Icons.check_circle_outline_rounded : Icons.payments_outlined;
    } else if (_canDeliver) {
      label = 'LISTO';
      icon = Icons.notifications_active_outlined;
    } else if (_canMarkPrepared) {
      label = 'PREPARANDO';
      icon = Icons.restaurant_outlined;
    } else {
      label = 'ENTREGADO';
      icon = Icons.check_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          side: const BorderSide(color: Color(0xFFDCDCE7)),
          foregroundColor: KomandaTheme.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => KomandaDetailPage(order: order)),
    );
  }

  Future<void> _charge(BuildContext context) async {
    // El diálogo compartido imprime el ticket del cliente tras confirmar el pago.
    final paid = await showKomandaPaymentDialog(context: context, order: order);
    if (paid && context.mounted) {
      // Recargar los pedidos tras el cobro para que los de domicilio y
      // para llevar pasen inmediatamente a Entregados y desaparezcan
      // del filtro predeterminado Preparación y pendiente.
      context.read<KomandaBloc>().add(const KomandaRefreshed(showLoading: false));
    }
  }

  Future<void> _advanceStatus(BuildContext context) async {
    // La API no permite entregar pedidos sin liquidar (HTTP 422).
    // Mostrar una acción de cobro antes de enviar un cambio de estado inválido.
    if (_canDeliver && !order.isPaid) {
      final shouldCharge = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pedido pendiente de pago'),
          content: Text('El folio ${order.shortFolio} no se ha cobrado. Cobra el pedido antes de entregarlo.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton.icon(onPressed: () => Navigator.pop(dialogContext, true), icon: const Icon(Icons.payments_outlined), label: const Text('Ir a cobrar')),
          ],
        ),
      );
      if (shouldCharge == true && context.mounted) {
        await _charge(context);
      }
      return; // Entrega explícita después de confirmar el pago.
    }
    final next = _canDeliver
        ? KomandaOrderStatus.atTable
        : KomandaOrderStatus.waiting;
    context.read<KomandaBloc>().add(
      KomandaOrderStatusChanged(
        orderId: order.id,
        status: next,
      ),
    );
  }

  String _orderTimeLabel(KomandaOrder order) {
    DateTime value;
    String prefix;

    if (order.status == KomandaOrderStatus.atTable ||
        order.status == KomandaOrderStatus.completed) {
      value = order.deliveredAt ??
          order.releasedAt ??
          order.paidAt ??
          order.readyAt ??
          order.createdAt;
      prefix = 'Entregado';
    } else if (order.status == KomandaOrderStatus.waiting ||
        order.status == KomandaOrderStatus.delivering) {
      value = order.readyAt ?? order.preparingAt ?? order.createdAt;
      prefix = 'Preparado';
    } else {
      value = order.preparingAt ?? order.createdAt;
      prefix = 'Preparando';
    }

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$prefix · $hour:$minute';
  }
}


class _EditOrderDialog extends StatefulWidget {
  final KomandaOrder order;
  final List<KomandaProduct> products;
  const _EditOrderDialog({required this.order, required this.products});

  @override
  State<_EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<_EditOrderDialog> {
  late List<KomandaOrderItem> workingItems;
  late List<TextEditingController> quantityControllers;
  late List<TextEditingController> priceControllers;
  int plateNumber = 1;
  late double deliveryFee;

  @override
  void initState() {
    super.initState();
    workingItems = List<KomandaOrderItem>.from(widget.order.items);
    quantityControllers = workingItems
        .map((item) => TextEditingController(text: item.quantity.toString()))
        .toList();
    deliveryFee = widget.order.deliveryFee > 0 ? widget.order.deliveryFee : 5;
    final existingPlates = workingItems.expand((e) => e.specifications).map((v) => RegExp(r'^Plato (\d+)', caseSensitive: false).firstMatch(v.trim())).whereType<RegExpMatch>().map((m) => int.tryParse(m.group(1) ?? '') ?? 1).toList();
    if (existingPlates.isNotEmpty) plateNumber = existingPlates.reduce((a, b) => a > b ? a : b);
    priceControllers = workingItems
        .map((item) => TextEditingController(text: item.unitPrice.toStringAsFixed(2)))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in quantityControllers) {
      controller.dispose();
    }
    for (final controller in priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addProduct() async {
    final item = await showKomandaOrderProductPicker(
      context: context,
      products: widget.products,
      plateNumber: plateNumber,
    );
    if (item == null || !mounted) return;
    setState(() {
      workingItems.add(item);
      quantityControllers.add(TextEditingController(text: item.quantity.toString()));
      priceControllers.add(TextEditingController(text: item.unitPrice.toStringAsFixed(2)));
    });
  }

  void _removeItem(int index) {
    if (workingItems.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El pedido debe conservar al menos un producto.')));
      return;
    }
    setState(() {
      workingItems.removeAt(index);
      quantityControllers.removeAt(index).dispose();
      priceControllers.removeAt(index).dispose();
    });
  }

  void _save() {
    final items = <KomandaOrderItem>[];
    for (var i = 0; i < workingItems.length; i++) {
      final original = workingItems[i];
      final quantity = int.tryParse(quantityControllers[i].text.trim());
      final price = double.tryParse(priceControllers[i].text.trim().replaceAll(',', '.'));
      if (quantity == null || quantity <= 0 || price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Revisa cantidad y precio de ${original.name}.')),
        );
        return;
      }
      items.add(original.copyWith(quantity: quantity, unitPrice: price));
    }
    final updated = widget.order.copyWith(
      items: items,
      deliveryFee: widget.order.isDelivery ? deliveryFee : 0,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar pedido #${widget.order.shortFolio}'),
      content: SizedBox(
        width: 560,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .65),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Expanded(child: Text('Plato para productos nuevos', style: TextStyle(fontWeight: FontWeight.w800))),
                IconButton(onPressed: plateNumber <= 1 ? null : () => setState(() => plateNumber--), icon: const Icon(Icons.remove_circle_outline)),
                Text('Plato $plateNumber', style: const TextStyle(fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => setState(() => plateNumber++), icon: const Icon(Icons.add_circle_outline)),
              ]),
              if (widget.order.isDelivery) ...[
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: Text('Costo de domicilio', style: TextStyle(fontWeight: FontWeight.w900))),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [5.0, 10.0, 15.0, 20.0].map((v) => ChoiceChip(
                  label: Text('\$${v.toStringAsFixed(0)}'),
                  selected: deliveryFee == v,
                  onSelected: (_) => setState(() => deliveryFee = v),
                )).toList()),
              ],
              if (widget.order.paidAmount > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: KomandaTheme.orange.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
                  child: Text('Ya pagado: ${komandaMoney(widget.order.paidAmount)}. Si el nuevo total aumenta, solo se cobrará la diferencia.', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
              const Divider(height: 20),
              Flexible(child: ListView.separated(
                shrinkWrap: true,
                itemCount: workingItems.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (_, index) {
                  if (index == workingItems.length) {
                    return SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _addProduct, icon: const Icon(Icons.add_shopping_cart_rounded), label: const Text('Agregar más producto')));
                  }
                  final item = workingItems[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900))), IconButton(tooltip: 'Quitar producto', onPressed: () => _removeItem(index), icon: const Icon(Icons.delete_outline))]),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: priceControllers[index],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Precio unitario',
                                prefixText: r'$ ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar cambios'),
        ),
      ],
    );
  }
}