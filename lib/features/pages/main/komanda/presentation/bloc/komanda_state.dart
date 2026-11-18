import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/komanda_product.dart';
import '../../domain/entities/komanda_waiter.dart';
import '../../domain/entities/waiter_call.dart';
import '../../domain/entities/komanda_ticket_config.dart';
import '../../domain/entities/komanda_category.dart';
import '../../domain/entities/komanda_table.dart';
import '../../domain/entities/komanda_cash_close.dart';
import '../../domain/entities/komanda_option_catalog.dart';

enum KomandaStatus { initial, loading, ready, saving, failure }
class KomandaState {
  final KomandaStatus status; final String? errorMessage; final String selectedTable;
  final List<KomandaProduct> products; final List<KomandaOrder> orders;
  final List<WaiterCall> waiterCalls; final List<KomandaWaiter> waiters;
  final Map<String, KomandaOrderItem> cart;
  final KomandaTicketConfig ticketConfig; final List<KomandaCategory> categories; final List<KomandaOptionCatalog> optionCatalogs; final List<KomandaTable> tables; final List<KomandaCashClose> cashClosures;
  const KomandaState({this.status=KomandaStatus.initial,this.errorMessage,this.selectedTable='',this.products=const[],this.orders=const[],this.waiterCalls=const[],this.waiters=const[],this.cart=const{},this.ticketConfig=const KomandaTicketConfig(),this.categories=const[],this.optionCatalogs=const[],this.tables=const[],this.cashClosures=const[]});
  List<KomandaOrder> get openOrders => orders.where((o)=>o.isOpen).toList();
  List<KomandaOrder> get completedOrdersList => orders.where((o)=>o.status==KomandaOrderStatus.completed).toList();
  List<WaiterCall> get pendingCallsList => waiterCalls.where((c)=>c.status==WaiterCallStatus.pending).toList();
  List<KomandaWaiter> get activeWaiters => waiters.where((w)=>w.active).toList();
  double get cartTotal => cart.values.fold(0,(s,i)=>s+i.total); int get pendingOrders=>openOrders.length; int get completedOrders=>completedOrdersList.length;
  List<KomandaOrder> get unattendedReadyOrders => orders.where((o)=>
      o.waiterId.trim().isNotEmpty &&
      (o.status==KomandaOrderStatus.waiting ||
       o.status==KomandaOrderStatus.delivering ||
       o.status==KomandaOrderStatus.atTable)).toList();
  double get salesTotal=>completedOrdersList.fold(0,(s,o)=>s+o.total);
  double get tipsTotal=>completedOrdersList.fold(0,(s,o)=>s+o.tipAmount);
  int get pendingCalls=>pendingCallsList.length + unattendedReadyOrders.length;
  bool get canContinueToProducts=>true; bool get canSaveOrder=>cart.isNotEmpty;
  KomandaOrder? openOrderForTable(String table){
    for(final o in orders){
      if(!o.table.split(',').map((name) => name.trim()).contains(table)) continue;
      if(o.status == KomandaOrderStatus.completed || o.status == KomandaOrderStatus.cancelled || o.releasedAt != null) continue;
      // El pago no libera la mesa: permanece ocupada hasta confirmar Liberar mesa.
      return o;
    }
    return null;
  }
  KomandaState copyWith({KomandaStatus? status,String? errorMessage,bool clearError=false,String? selectedTable,List<KomandaProduct>? products,List<KomandaOrder>? orders,List<WaiterCall>? waiterCalls,List<KomandaWaiter>? waiters,Map<String,KomandaOrderItem>? cart,KomandaTicketConfig? ticketConfig,List<KomandaCategory>? categories,List<KomandaOptionCatalog>? optionCatalogs,List<KomandaTable>? tables,List<KomandaCashClose>? cashClosures})=>KomandaState(status:status??this.status,errorMessage:clearError?null:errorMessage??this.errorMessage,selectedTable:selectedTable??this.selectedTable,products:products??this.products,orders:orders??this.orders,waiterCalls:waiterCalls??this.waiterCalls,waiters:waiters??this.waiters,cart:cart??this.cart,ticketConfig:ticketConfig??this.ticketConfig,categories:categories??this.categories,optionCatalogs:optionCatalogs??this.optionCatalogs,tables:tables??this.tables,cashClosures:cashClosures??this.cashClosures);
}
