import '../entities/komanda_order.dart';
import '../entities/komanda_product.dart';
import '../entities/komanda_waiter.dart';
import '../entities/waiter_call.dart';
import '../entities/komanda_ticket_config.dart';
import '../entities/komanda_category.dart';
import '../entities/komanda_table.dart';
import '../entities/komanda_cash_close.dart';
import '../entities/komanda_option_catalog.dart';
import '../repositories/komanda_repository.dart';

class InitKomanda { final KomandaRepository repository; const InitKomanda(this.repository); Future<void> call() => repository.init(); }
class GetKomandaProducts { final KomandaRepository repository; const GetKomandaProducts(this.repository); Future<List<KomandaProduct>> call() => repository.getProducts(); }
class DeleteKomandaProduct { final KomandaRepository repository; const DeleteKomandaProduct(this.repository); Future<void> call(String id)=>repository.deleteProduct(id); }
class SaveKomandaProduct { final KomandaRepository repository; const SaveKomandaProduct(this.repository); Future<void> call(KomandaProduct product) => repository.saveProduct(product); }
class GetKomandaOrders { final KomandaRepository repository; const GetKomandaOrders(this.repository); Future<List<KomandaOrder>> call() => repository.getOrders(); }
class SaveKomandaOrder { final KomandaRepository repository; const SaveKomandaOrder(this.repository); Future<void> call(KomandaOrder order) => repository.saveOrder(order); }
class UpdateKomandaOrder { final KomandaRepository repository; const UpdateKomandaOrder(this.repository); Future<void> call(KomandaOrder order) => repository.updateOrder(order); }
class UpdateKomandaOrderStatus { final KomandaRepository repository; const UpdateKomandaOrderStatus(this.repository); Future<void> call(String orderId, KomandaOrderStatus status) => repository.updateOrderStatus(orderId, status); }
class AssignWaiterToOrder { final KomandaRepository repository; const AssignWaiterToOrder(this.repository); Future<void> call(String orderId, KomandaWaiter waiter) => repository.assignWaiterToOrder(orderId, waiter); }
class GetWaiterCalls { final KomandaRepository repository; const GetWaiterCalls(this.repository); Future<List<WaiterCall>> call() => repository.getWaiterCalls(); }
class SaveWaiterCall { final KomandaRepository repository; const SaveWaiterCall(this.repository); Future<void> call(WaiterCall call) => repository.saveWaiterCall(call); }
class UpdateWaiterCallStatus { final KomandaRepository repository; const UpdateWaiterCallStatus(this.repository); Future<void> call(String callId, WaiterCallStatus status, {KomandaWaiter? waiter}) => repository.updateWaiterCallStatus(callId, status, waiter: waiter); }
class GetKomandaWaiters { final KomandaRepository repository; const GetKomandaWaiters(this.repository); Future<List<KomandaWaiter>> call() => repository.getWaiters(); }
class SaveKomandaWaiter { final KomandaRepository repository; const SaveKomandaWaiter(this.repository); Future<void> call(KomandaWaiter waiter) => repository.saveWaiter(waiter); }

class GetKomandaTicketConfig { final KomandaRepository repository; const GetKomandaTicketConfig(this.repository); Future<KomandaTicketConfig> call()=>repository.getTicketConfig(); }
class SaveKomandaTicketConfig { final KomandaRepository repository; const SaveKomandaTicketConfig(this.repository); Future<void> call(KomandaTicketConfig c)=>repository.saveTicketConfig(c); }

class DeleteKomandaWaiter { final KomandaRepository repository; const DeleteKomandaWaiter(this.repository); Future<void> call(String id)=>repository.deleteWaiter(id); }
class GetKomandaCategories { final KomandaRepository repository; const GetKomandaCategories(this.repository); Future<List<KomandaCategory>> call()=>repository.getCategories(); }
class SaveKomandaCategory { final KomandaRepository repository; const SaveKomandaCategory(this.repository); Future<void> call(KomandaCategory c)=>repository.saveCategory(c); }
class DeleteKomandaCategory { final KomandaRepository repository; const DeleteKomandaCategory(this.repository); Future<void> call(String id)=>repository.deleteCategory(id); }
class GetKomandaOptionCatalogs { final KomandaRepository repository; const GetKomandaOptionCatalogs(this.repository); Future<List<KomandaOptionCatalog>> call()=>repository.getOptionCatalogs(); }
class SaveKomandaOptionCatalog { final KomandaRepository repository; const SaveKomandaOptionCatalog(this.repository); Future<void> call(KomandaOptionCatalog c)=>repository.saveOptionCatalog(c); }
class DeleteKomandaOptionCatalog { final KomandaRepository repository; const DeleteKomandaOptionCatalog(this.repository); Future<void> call(String id)=>repository.deleteOptionCatalog(id); }
class GetKomandaTables { final KomandaRepository repository; const GetKomandaTables(this.repository); Future<List<KomandaTable>> call()=>repository.getTables(); }
class SaveKomandaTable { final KomandaRepository repository; const SaveKomandaTable(this.repository); Future<void> call(KomandaTable t)=>repository.saveTable(t); }
class DeleteKomandaTable { final KomandaRepository repository; const DeleteKomandaTable(this.repository); Future<void> call(String id)=>repository.deleteTable(id); }
class GetKomandaCashClosures { final KomandaRepository repository; const GetKomandaCashClosures(this.repository); Future<List<KomandaCashClose>> call()=>repository.getCashClosures(); }
class SaveKomandaCashClose { final KomandaRepository repository; const SaveKomandaCashClose(this.repository); Future<void> call(KomandaCashClose c)=>repository.saveCashClose(c); }
