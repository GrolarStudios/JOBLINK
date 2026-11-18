import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../core/printing/komanda_ticket_print_service.dart';
import '../../domain/entities/komanda_order.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';

class KomandaPerformancePage extends StatefulWidget {
  const KomandaPerformancePage({super.key});
  @override State<KomandaPerformancePage> createState() => _KomandaPerformancePageState();
}

class _KomandaPerformancePageState extends State<KomandaPerformancePage> {
  int? selectedDay;
  DateTime? selectedWeek;
  DateTime _weekStart(DateTime d) { final day=DateTime(d.year,d.month,d.day); return day.subtract(Duration(days:day.weekday-1)); }
  String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String _money(num v) => komandaMoney(v);

  @override Widget build(BuildContext context) => BlocBuilder<KomandaBloc,KomandaState>(builder:(context,state){
    final allPaid=state.orders.where((o)=>o.isPaid&&o.status!=KomandaOrderStatus.cancelled).toList();
    final weeks=allPaid.map((o)=>_weekStart(o.paidAt??o.createdAt)).toSet().toList()..sort((a,b)=>b.compareTo(a));
    final paid=selectedWeek==null?allPaid:allPaid.where((o)=>_weekStart(o.paidAt??o.createdAt)==selectedWeek).toList();
    final totals=List<double>.filled(7,0), tickets=List<int>.filled(7,0), pieces=List<int>.filled(7,0);
    for(final o in paid){ final i=(o.paidAt??o.createdAt).weekday-1; totals[i]+=o.total+o.tipAmount; tickets[i]++; pieces[i]+=o.items.fold<int>(0,(a,x)=>a+x.quantity); }
    int best=0; for(var i=1;i<7;i++){if(totals[i]>totals[best])best=i;}
    final total=totals.fold<double>(0,(a,b)=>a+b), avg=paid.isEmpty?0.0:total/paid.length, totalPieces=pieces.fold<int>(0,(a,b)=>a+b);
    const days=['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'], longDays=['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    final order=List<int>.generate(7,(i)=>i)..sort((a,b)=>totals[b].compareTo(totals[a])); final ranks=List<int>.filled(7,0); for(var i=0;i<7;i++){ranks[order[i]]=i+1;}
    return KomandaPhoneFrame(child:Column(children:[
      KomandaHeader(title:'Rendimiento',subtitle:'Inteligencia de ventas',onLeadingTap:()=>Navigator.maybePop(context)),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(16,4,16,20),children:[
        KomandaCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Periodo de rendimiento',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)), const SizedBox(height:4),
          const Text('Consulta una semana específica o todas las semanas registradas.',style:TextStyle(fontSize:12,color:KomandaTheme.softText)), const SizedBox(height:12),
          Row(children:[Expanded(child:DropdownButtonFormField<String>(
            value:selectedWeek==null?'all':selectedWeek!.toIso8601String(), decoration:const InputDecoration(labelText:'Semana',border:OutlineInputBorder()),
            items:[const DropdownMenuItem(value:'all',child:Text('Todas las semanas')),...weeks.map((w)=>DropdownMenuItem(value:w.toIso8601String(),child:Text('${_dateLabel(w)} al ${_dateLabel(w.add(const Duration(days:6)))}')))],
            onChanged:(v)=>setState((){selectedDay=null;selectedWeek=v==null||v=='all'?null:DateTime.parse(v);}),
          )),const SizedBox(width:10),FilledButton.icon(
            onPressed:paid.isEmpty?null:()=>KomandaTicketPrintService.printPerformanceSummary(
              from:selectedWeek??paid.map((o)=>o.createdAt).reduce((a,b)=>a.isBefore(b)?a:b), to:selectedWeek?.add(const Duration(days:6))??paid.map((o)=>o.createdAt).reduce((a,b)=>a.isAfter(b)?a:b),
              total:total,tickets:paid.length,average:avg,pieces:totalPieces,dayNames:longDays,dayTotals:totals,dayTickets:tickets,dayPieces:pieces),
            icon:const Icon(Icons.print_rounded),label:const Text('IMPRIMIR'))])
        ])),
        KomandaCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Tu mejor día de venta',style:TextStyle(color:KomandaTheme.softText,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(paid.isEmpty?'Sin información todavía':longDays[best],style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(paid.isEmpty?'Registra ventas para comenzar el análisis.':'${_money(totals[best])} acumulados · ${tickets[best]} tickets',style:const TextStyle(color:KomandaTheme.purple,fontWeight:FontWeight.w800))])),
        KomandaCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Ventas por día de la semana',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:4),const Text('Toca una barra para consultar el importe vendido.',style:TextStyle(color:KomandaTheme.softText,fontSize:12)),const SizedBox(height:12),if(selectedDay!=null)Container(width:double.infinity,margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:KomandaTheme.purple.withOpacity(0.08),borderRadius:BorderRadius.circular(12)),child:Row(children:[Expanded(child:Text(longDays[selectedDay!],style:const TextStyle(fontWeight:FontWeight.w900))),Text(_money(totals[selectedDay!]),style:const TextStyle(fontWeight:FontWeight.w900,color:KomandaTheme.purple))])),SizedBox(height:190,child:_WeekBarChart(values:totals,labels:days,selectedIndex:selectedDay,onSelected:(i)=>setState(()=>selectedDay=i)))])),
        KomandaCard(child:Wrap(spacing:18,runSpacing:12,children:[Text('Ventas: ${_money(total)}'),Text('Tickets: ${paid.length}'),Text('Ticket promedio: ${_money(avg)}'),Text('Piezas: $totalPieces')])),
        KomandaCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Detalle semanal',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:8),...List.generate(7,(i)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[CircleAvatar(radius:14,child:Text('${ranks[i]}')),const SizedBox(width:9),SizedBox(width:76,child:Text(longDays[i],style:const TextStyle(fontWeight:FontWeight.w800))),Expanded(child:Text('${tickets[i]} tickets · ${pieces[i]} pzas',style:const TextStyle(fontSize:11,color:KomandaTheme.softText))),Text(_money(totals[i]),style:const TextStyle(fontWeight:FontWeight.w900))])))])),
      ])),const BottomNavMock(index:-1)
    ]));
  });
}

class _WeekBarChart extends StatelessWidget{
  final List<double> values; final List<String> labels; final int? selectedIndex; final ValueChanged<int> onSelected;
  const _WeekBarChart({required this.values,required this.labels,required this.selectedIndex,required this.onSelected});
  @override Widget build(BuildContext context){final maxValue=math.max(1.0,values.fold<double>(0,math.max)).toDouble();return Row(crossAxisAlignment:CrossAxisAlignment.end,children:List.generate(values.length,(i){final selected=selectedIndex==i;final double height=values[i]==0?0.02:(values[i]/maxValue).clamp(0.08,1.0).toDouble();return Expanded(child:InkWell(onTap:()=>onSelected(i),child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:Column(mainAxisAlignment:MainAxisAlignment.end,children:[Expanded(child:Align(alignment:Alignment.bottomCenter,child:FractionallySizedBox(heightFactor:height,widthFactor:selected?0.86:0.72,child:Container(decoration:BoxDecoration(color:selected?KomandaTheme.purple:KomandaTheme.purple.withOpacity(0.22),borderRadius:const BorderRadius.vertical(top:Radius.circular(8))))))),const SizedBox(height:7),Text(labels[i],style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:selected?KomandaTheme.purple:KomandaTheme.softText))]))));}));}
}
