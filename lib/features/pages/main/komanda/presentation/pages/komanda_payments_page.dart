import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../domain/entities/komanda_order.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';

class KomandaPaymentsPage extends StatefulWidget {
  const KomandaPaymentsPage({super.key});
  @override State<KomandaPaymentsPage> createState()=>_KomandaPaymentsPageState();
}
class _KomandaPaymentsPageState extends State<KomandaPaymentsPage>{
  DateTime selectedDate=DateTime.now();
  String filter = 'Todos';
  @override Widget build(BuildContext context)=>BlocBuilder<KomandaBloc,KomandaState>(builder:(context,state){
    final rows=state.orders.where((o)=>o.isPaid&&o.status!=KomandaOrderStatus.cancelled&&o.paidAt!=null&&_sameDay(o.paidAt!.toLocal(),selectedDate)).toList()..sort((a,b)=>b.paidAt!.compareTo(a.paidAt!));
    final total=rows.fold<double>(0,(a,o)=>a+o.total+o.tipAmount);
    final cash=rows.where((o)=>_paymentType(o.paymentMethod)=='Efectivo').fold<double>(0,(a,o)=>a+o.total+o.tipAmount);
    final card=rows.where((o)=>_paymentType(o.paymentMethod)=='Tarjeta').fold<double>(0,(a,o)=>a+o.total+o.tipAmount);
    final transfer=rows.where((o)=>_paymentType(o.paymentMethod)=='Transferencia').fold<double>(0,(a,o)=>a+o.total+o.tipAmount);
    final visible=filter=='Todos'?rows:rows.where((o)=>_paymentType(o.paymentMethod)==filter).toList();
    return KomandaPhoneFrame(child:Column(children:[
      KomandaHeader(title:'Cobros',subtitle:'Lista de cobros realizados',onLeadingTap:()=>Navigator.maybePop(context)),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,20),children:[
        Row(children:[Expanded(child:OutlinedButton.icon(onPressed:_pickDate,icon:const Icon(Icons.calendar_month_rounded),label:Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'))),const SizedBox(width:10),Text('${rows.length} cobros',style:const TextStyle(color:KomandaTheme.softText,fontWeight:FontWeight.w800))]),
        const SizedBox(height:14),
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:LinearGradient(colors:[KomandaTheme.purple,KomandaTheme.purple.withOpacity(.82)]),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[Icon(Icons.account_balance_wallet_outlined,color:Colors.white),SizedBox(width:8),Text('Total cobrado',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700))]),
          const SizedBox(height:8),Text(_money(total),style:const TextStyle(fontSize:32,fontWeight:FontWeight.w900,color:Colors.white)),
          const SizedBox(height:4),Text('${rows.length} pagos registrados en el día',style:const TextStyle(color:Colors.white70)),
        ])),
        const SizedBox(height:12),
        LayoutBuilder(builder:(context,c)=>Wrap(spacing:8,runSpacing:8,children:[_mini('Efectivo',cash,Icons.payments_outlined,(c.maxWidth-16)/3),_mini('Tarjeta',card,Icons.credit_card_rounded,(c.maxWidth-16)/3),_mini('Transferencia',transfer,Icons.swap_horiz_rounded,(c.maxWidth-16)/3)])),
        const SizedBox(height:18),
        const Text('Movimientos',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
        const SizedBox(height:8),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:['Todos','Efectivo','Tarjeta','Transferencia'].map((item)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(item),selected:filter==item,onSelected:(_)=>setState(()=>filter=item)))).toList())),
        const SizedBox(height:12),
        if(visible.isEmpty) const Padding(padding:EdgeInsets.symmetric(vertical:36),child:Center(child:Text('No hay cobros para este filtro.',style:TextStyle(color:KomandaTheme.softText))))
        else ...visible.map(_payment),
      ])),
      const BottomNavMock(index:-1),
    ]));
  });
  String _paymentType(String raw){final x=raw.toLowerCase();if(x.contains('efect')||x=='cash')return 'Efectivo';if(x.contains('tarj')||x=='card')return 'Tarjeta';if(x.contains('transf')||x=='transfer')return 'Transferencia';return 'Otro';}
  Widget _mini(String title,double amount,IconData icon,double width)=>SizedBox(width:width,child:Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:14),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:KomandaTheme.border),borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:KomandaTheme.purple,size:20),const SizedBox(height:8),Text(title,maxLines:1,style:const TextStyle(fontSize:11,color:KomandaTheme.softText)),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(_money(amount),style:const TextStyle(fontWeight:FontWeight.w900)))])));
  Widget _payment(KomandaOrder o){
    final amount=o.total+o.tipAmount;
    final received=o.amountReceived>0?o.amountReceived:amount;
    final difference=received-amount;
    return KomandaCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:KomandaTheme.purple.withOpacity(.08),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.receipt_long_rounded,color:KomandaTheme.purple)),const SizedBox(width:10),Expanded(child:Text('Ticket #${o.shortFolio}',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900))),Text(_money(amount),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900,color:KomandaTheme.purple))]),
      const SizedBox(height:4),Text('${o.paymentMethod.isEmpty?'Sin método':o.paymentMethod} · ${_time(o.paidAt!)}',style:const TextStyle(color:KomandaTheme.softText,fontWeight:FontWeight.w700)),
      const Divider(height:20),
      LayoutBuilder(builder:(context,c)=>Wrap(spacing:8,runSpacing:8,children:[SizedBox(width:(c.maxWidth-16)/3,child:_value('Total',amount)),SizedBox(width:(c.maxWidth-16)/3,child:_value('Recibido',received)),SizedBox(width:(c.maxWidth-16)/3,child:_value('Cambio / diferencia',difference,color:difference.abs()<.01?KomandaTheme.green:KomandaTheme.orange))])),
    ]));
  }
  Widget _value(String label,double value,{Color? color})=>Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:const Color(0xFFF8F7FC),borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:10,color:KomandaTheme.softText,fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(_money(value),style:TextStyle(fontWeight:FontWeight.w900,color:color??KomandaTheme.text))]));
  Future<void> _pickDate()async{final d=await showDatePicker(context:context,initialDate:selectedDate,firstDate:DateTime(2024),lastDate:DateTime.now().add(const Duration(days:1)));if(d!=null&&mounted)setState(()=>selectedDate=d);}
  bool _sameDay(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;
  String _time(DateTime d){final x=d.toLocal();return '${x.hour.toString().padLeft(2,'0')}:${x.minute.toString().padLeft(2,'0')}';}
  String _money(num v)=>komandaMoney(v);
}
