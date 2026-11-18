import 'package:flutter/material.dart';
import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../data/datasources/komanda_remote_datasource.dart';
import '../widgets/komanda_widgets.dart';

enum _FinancePeriod { day, month, year, custom }

class KomandaFinancesPage extends StatefulWidget {
  final KomandaRemoteDataSource remote;
  const KomandaFinancesPage({super.key, required this.remote});
  @override State<KomandaFinancesPage> createState() => _KomandaFinancesPageState();
}

class _KomandaFinancesPageState extends State<KomandaFinancesPage> {
  List<Map<String,dynamic>> expenses = const [];
  List<Map<String,dynamic>> orders = const [];
  bool loading = true;
  int page = 0;
  static const pageSize = 50;
  _FinancePeriod period = _FinancePeriod.month;
  DateTime anchor = DateTime.now();
  DateTime? customFrom;
  DateTime? customTo;

  @override void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    if(mounted)setState(()=>loading=true);
    try {
      final r=await Future.wait([widget.remote.getExpenses(),widget.remote.getOrders()]);
      if(mounted)setState((){expenses=r[0];orders=r[1];loading=false;page=0;});
    } catch(e){ if(mounted)setState(()=>loading=false); }
  }

  DateTime? _date(dynamic v){
    if(v==null)return null;
    final s='$v'.trim();
    if(s.isEmpty)return null;
    return DateTime.tryParse(s)?.toLocal();
  }
  DateTime get _from {
    switch(period){
      case _FinancePeriod.day:return DateTime(anchor.year,anchor.month,anchor.day);
      case _FinancePeriod.month:return DateTime(anchor.year,anchor.month,1);
      case _FinancePeriod.year:return DateTime(anchor.year,1,1);
      case _FinancePeriod.custom:return DateTime((customFrom??anchor).year,(customFrom??anchor).month,(customFrom??anchor).day);
    }
  }
  DateTime get _toExclusive {
    switch(period){
      case _FinancePeriod.day:return _from.add(const Duration(days:1));
      case _FinancePeriod.month:return anchor.month==12?DateTime(anchor.year+1,1,1):DateTime(anchor.year,anchor.month+1,1);
      case _FinancePeriod.year:return DateTime(anchor.year+1,1,1);
      case _FinancePeriod.custom:
        final t=customTo??customFrom??anchor;
        return DateTime(t.year,t.month,t.day).add(const Duration(days:1));
    }
  }
  bool _inside(DateTime? d)=>d!=null&&!d.isBefore(_from)&&d.isBefore(_toExclusive);

  List<Map<String,dynamic>> get _filteredExpenses=>expenses.where((e)=>_inside(_date(e['expense_date']??e['created_at']??e['createdAt']))).toList();
  List<Map<String,dynamic>> get _filteredSales=>orders.where((o){
    final status='${o['status']??''}'.toLowerCase();
    final paid=o['is_paid']==true||o['isPaid']==true||o['is_paid']==1||'${o['is_paid']}'=='1';
    final completed=status=='completed'||status=='finalizado'||status=='finished';
    final d=_date(o['paid_at']??o['paidAt']??o['created_at']??o['createdAt']);
    return (paid||completed)&&_inside(d);
  }).toList();

  double _expenseTotal()=>_filteredExpenses.fold(0,(s,e)=>s+(double.tryParse('${e['amount']??0}')??0));
  double _orderTotal(Map<String,dynamic> o){
    final direct=double.tryParse('${o['total']??o['grand_total']??o['paid_amount']??o['paidAmount']??''}');
    if(direct!=null&&direct>0)return direct;
    double sum=0;
    for(final raw in (o['items'] as List? ?? const [])){
      if(raw is! Map)continue;
      final q=double.tryParse('${raw['quantity']??1}')??1;
      final p=double.tryParse('${raw['unit_price']??raw['unitPrice']??raw['price']??0}')??0;
      sum+=q*p;
    }
    sum+=double.tryParse('${o['delivery_fee']??o['deliveryFee']??0}')??0;
    return sum;
  }
  double _salesTotal()=>_filteredSales.fold(0,(s,o)=>s+_orderTotal(o));

  String _d(DateTime d)=>'${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String get _periodLabel {
    const months=['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    switch(period){
      case _FinancePeriod.day:return _d(anchor);
      case _FinancePeriod.month:return '${months[anchor.month-1]} ${anchor.year}';
      case _FinancePeriod.year:return 'Año ${anchor.year}';
      case _FinancePeriod.custom:return '${_d(_from)} – ${_d(_toExclusive.subtract(const Duration(days:1)))}';
    }
  }

  Future<void> _pickDay() async { final d=await showDatePicker(context:context,initialDate:anchor,firstDate:DateTime(2020),lastDate:DateTime(2100)); if(d!=null)setState((){anchor=d;period=_FinancePeriod.day;page=0;}); }
  Future<void> _pickMonth() async {
    final d=await showDatePicker(context:context,initialDate:anchor,firstDate:DateTime(2020),lastDate:DateTime(2100),helpText:'Selecciona cualquier día del mes');
    if(d!=null)setState((){anchor=DateTime(d.year,d.month,1);period=_FinancePeriod.month;page=0;});
  }
  Future<void> _pickYear() async {
    final y=await showDialog<int>(context:context,builder:(c)=>AlertDialog(title:const Text('Seleccionar año'),content:SizedBox(width:300,height:300,child:YearPicker(firstDate:DateTime(2020),lastDate:DateTime(2100),selectedDate:anchor,onChanged:(d)=>Navigator.pop(c,d.year)))));
    if(y!=null)setState((){anchor=DateTime(y,1,1);period=_FinancePeriod.year;page=0;});
  }
  Future<void> _pickRange() async {
    final r=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDateRange:DateTimeRange(start:customFrom??DateTime(anchor.year,anchor.month,1),end:customTo??anchor));
    if(r!=null)setState((){customFrom=r.start;customTo=r.end;period=_FinancePeriod.custom;page=0;});
  }

  @override Widget build(BuildContext context){
    final sales=_salesTotal(), exp=_expenseTotal(), result=sales-exp;
    final filteredExpenses=_filteredExpenses;
    final pages=(filteredExpenses.length/pageSize).ceil().clamp(1,999999);
    if(page>=pages)page=pages-1;
    final visible=filteredExpenses.skip(page*pageSize).take(pageSize).toList();
    return KomandaPhoneFrame(child:Column(children:[
      const KomandaHeader(title:'Finanzas',bell:false),
      Expanded(child:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[
        KomandaCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Periodo financiero',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:10),
          Wrap(spacing:8,runSpacing:8,children:[
            ChoiceChip(label:const Text('Día'),selected:period==_FinancePeriod.day,onSelected:(_)=>_pickDay()),
            ChoiceChip(label:const Text('Mes'),selected:period==_FinancePeriod.month,onSelected:(_)=>_pickMonth()),
            ChoiceChip(label:const Text('Año'),selected:period==_FinancePeriod.year,onSelected:(_)=>_pickYear()),
            ChoiceChip(label:const Text('Rango'),selected:period==_FinancePeriod.custom,onSelected:(_)=>_pickRange()),
          ]),const SizedBox(height:10),
          Row(children:[const Icon(Icons.date_range,color:KomandaTheme.purple),const SizedBox(width:8),Expanded(child:Text(_periodLabel,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)))]),
        ])),
        const SizedBox(height:12),
        Wrap(spacing:10,runSpacing:10,children:[
          _metric('Ventas del periodo',sales,Icons.payments),
          _metric('Egresos del periodo',exp,Icons.trending_down),
          _metric('Resultado del periodo',result,Icons.account_balance_wallet),
          _metric('Ventas / tickets',_filteredSales.length.toDouble(),Icons.receipt_long,money:false),
        ]),
        const SizedBox(height:18),
        _statement('Estado de resultados · $_periodLabel',[_line('Ingresos / ventas',sales),_line('(-) Egresos operativos',-exp),_line('Utilidad / pérdida del periodo',result,bold:true)]),
        const SizedBox(height:12),
        _statement('Balance general operativo · $_periodLabel',[_line('ACTIVO · Disponible generado',result),_line('PASIVO · Registrado',0),_line('CAPITAL / RESULTADO DEL PERIODO',result,bold:true)],note:'Vista operativa calculada únicamente con movimientos del periodo seleccionado.'),
        const SizedBox(height:18),
        Row(children:[Expanded(child:Text('Egresos · $_periodLabel',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:_addExpense,icon:const Icon(Icons.add),label:const Text('Registrar egreso'))]),
        const SizedBox(height:8),
        if(filteredExpenses.isEmpty)const KomandaCard(child:Text('No hay egresos registrados en este periodo.')),
        ...visible.map((e)=>KomandaCard(child:ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(child:Icon(Icons.receipt_long_outlined)),title:Text('${e['concept']??'Egreso'}',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${e['expense_date']??''}${('${e['notes']??''}').trim().isEmpty?'':' · ${e['notes']}'}'),trailing:Text('-${komandaMoney(double.tryParse('${e['amount']??0}')??0)}',style:const TextStyle(fontWeight:FontWeight.w900,color:KomandaTheme.red))))),
        if(filteredExpenses.length>pageSize)_pager(page,pages),
      ])))
    ]));
  }

  Widget _metric(String t,double v,IconData i,{bool money=true})=>SizedBox(width:170,child:KomandaCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:KomandaTheme.purple),const SizedBox(height:8),Text(t,style:const TextStyle(color:KomandaTheme.softText,fontWeight:FontWeight.w700)),Text(money?komandaMoney(v):v.toInt().toString(),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))])));
  Widget _line(String label,double value,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(label,style:TextStyle(fontWeight:bold?FontWeight.w900:FontWeight.w600))),Text(komandaMoney(value),style:TextStyle(fontWeight:bold?FontWeight.w900:FontWeight.w700))]));
  Widget _statement(String title,List<Widget> rows,{String? note})=>KomandaCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const Divider(height:22),...rows,if(note!=null)...[const Divider(),Text(note,style:const TextStyle(fontSize:12,color:KomandaTheme.softText))]]));
  Widget _pager(int current,int total)=>Padding(padding:const EdgeInsets.only(top:8),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:current>0?()=>setState(()=>page--):null,icon:const Icon(Icons.chevron_left)),Text('Página ${current+1} de $total · 50 por página',style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:current+1<total?()=>setState(()=>page++):null,icon:const Icon(Icons.chevron_right))]));

  Future<void> _addExpense() async {
    final concept = TextEditingController();
    final amount = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String category = 'Insumos y materia prima';
    bool saving = false;
    final categories = <String>[
      'Insumos y materia prima',
      'Nómina',
      'Renta y servicios',
      'Transporte y entregas',
      'Mantenimiento',
      'Publicidad',
      'Impuestos',
      'Otros gastos',
    ];
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: const Text('Agregar egreso'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Registra un gasto del negocio. Se descontará de los resultados del mes.'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: '¿En qué gastaste?',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((item) => DropdownMenuItem(
                          value: item, child: Text(item),
                        )).toList(),
                        onChanged: saving ? null : (value) => update(() => category = value ?? category),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: concept,
                        enabled: !saving,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Descripción del gasto',
                          hintText: 'Ej. Compra de tortillas',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Escribe qué compraste o pagaste' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amount,
                        enabled: !saving,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '¿Cuánto pagaste?',
                          prefixText: r'$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                          return number == null || !number.isFinite || number <= 0
                              ? 'Ingresa un importe mayor a cero' : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notes,
                        enabled: !saving,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          hintText: 'Ej. Factura o proveedor',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: saving ? null : () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  update(() => saving = true);
                  try {
                    await widget.remote.createExpense({
                      'concept': concept.text.trim(),
                      'amount': double.parse(amount.text.trim().replaceAll(',', '.')),
                      'notes': '$category${notes.text.trim().isEmpty ? '' : ' · ${notes.text.trim()}'}',
                    });
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    await _load();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Egreso registrado correctamente.')),
                    );
                  } catch (error) {
                    if (dialogContext.mounted) {
                      update(() => saving = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('No se pudo guardar el egreso: $error')),
                      );
                    }
                  }
                },
                icon: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Guardando...' : 'Guardar egreso'),
              ),
            ],
          ),
        ),
      );
    } finally {
      // Los campos pertenecen al diálogo y se liberan después de cerrarlo.
      concept.dispose();
      amount.dispose();
      notes.dispose();
    }
  }
}
