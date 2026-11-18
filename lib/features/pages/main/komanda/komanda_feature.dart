import 'package:ayko_soft/features/pages/main/komanda/presentation/chef/pages/komanda_chef_orders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/route_names.dart';
import 'data/datasources/komanda_auth_local_datasource.dart';
import 'data/datasources/komanda_remote_datasource.dart';
import 'data/repositories/komanda_repository_impl.dart';
import 'domain/entities/komanda_order.dart';
import 'domain/entities/komanda_session.dart';
import 'core/komanda_permissions.dart';
import 'domain/usecases/komanda_usecases.dart';
import 'presentation/bloc/komanda_bloc.dart';
import 'presentation/bloc/komanda_event.dart';
import 'presentation/pages/komanda_login_page.dart';
import 'presentation/pages/komanda_pages.dart';
import 'presentation/pages/komanda_tables_overview_page.dart';
import 'presentation/pages/komanda_tables_admin_page.dart';
import 'presentation/pages/komanda_categories_page.dart';
import 'presentation/pages/komanda_cash_close_page.dart';
import 'presentation/pages/komanda_payments_page.dart';
import 'presentation/pages/komanda_performance_page.dart';
import 'presentation/pages/komanda_finances_page.dart';
import 'presentation/pages/komanda_users_admin_page.dart';
import 'presentation/pages/komanda_profile_page.dart';
import 'presentation/pages/komanda_public_order_status_page.dart';
import 'presentation/waiter_management/pages/komanda_waiters_page.dart';

class KomandaFeature extends StatefulWidget {
  final String? initialRoute;

  const KomandaFeature({super.key, this.initialRoute});

  @override
  State<KomandaFeature> createState() => _KomandaFeatureState();
}

class _KomandaFeatureState extends State<KomandaFeature> {
  final _authLocal = KomandaAuthLocalDataSource();

  KomandaSession? _session;
  KomandaRepositoryImpl? _repository;
  KomandaBloc? _bloc;
  bool _booting = true;
  String? _bootError;
  int _loginGeneration = 0;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final session = await _authLocal.getSession();
      if (session != null) {
        await _activateSession(session);
      }
    } catch (error) {
      _bootError = error.toString();
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  Future<void> _activateSession(KomandaSession session) async {
    await _bloc?.close();

    final remote = HttpKomandaRemoteDataSource()..setToken(session.token);
    final repository = KomandaRepositoryImpl(
      remoteDataSource: remote,
      session: session,
    );

    final bloc = KomandaBloc(
      restaurantId: session.restaurantId,
      initKomanda: InitKomanda(repository),
      getProducts: GetKomandaProducts(repository),
      saveProduct: SaveKomandaProduct(repository),
      deleteProduct: DeleteKomandaProduct(repository),
      getTicketConfig: GetKomandaTicketConfig(repository),
      saveTicketConfig: SaveKomandaTicketConfig(repository),
      getOrders: GetKomandaOrders(repository),
      saveOrder: SaveKomandaOrder(repository),
      updateOrder: UpdateKomandaOrder(repository),
      updateOrderStatus: UpdateKomandaOrderStatus(repository),
      getWaiterCalls: GetWaiterCalls(repository),
      saveWaiterCall: SaveWaiterCall(repository),
      updateWaiterCallStatus: UpdateWaiterCallStatus(repository),
      getWaiters: GetKomandaWaiters(repository),
      saveWaiter: SaveKomandaWaiter(repository),
      assignWaiterToOrder: AssignWaiterToOrder(repository),
      deleteWaiter: DeleteKomandaWaiter(repository),
      getCategories: GetKomandaCategories(repository),
      saveCategory: SaveKomandaCategory(repository),
      deleteCategory: DeleteKomandaCategory(repository),
      getOptionCatalogs: GetKomandaOptionCatalogs(repository),
      saveOptionCatalog: SaveKomandaOptionCatalog(repository),
      deleteOptionCatalog: DeleteKomandaOptionCatalog(repository),
      getTables: GetKomandaTables(repository),
      saveTable: SaveKomandaTable(repository),
      deleteTable: DeleteKomandaTable(repository),
      getCashClosures: GetKomandaCashClosures(repository),
      saveCashClose: SaveKomandaCashClose(repository),
    )..add(const KomandaStarted());

    _session = session;
    _repository = repository;
    _bloc = bloc;
  }

  Future<KomandaLoginResult> _login(String username, String password) async {
    try {
      final remote = HttpKomandaRemoteDataSource();
      final response = await remote.login(username, password);
      final session = KomandaSession.fromLoginResponse(response);
      await _authLocal.saveSession(session);
      await _activateSession(session);
      if (mounted) setState(() {});
      return const KomandaLoginResult(success: true);
    } catch (error) {
      return KomandaLoginResult(
        success: false,
        message: error.toString(),
      );
    }
  }

  Future<void> _logout() async {
    final oldBloc = _bloc;
    final oldRepository = _repository;
    final remote = oldRepository?.remoteDataSource;

    // 1) La sesión local se elimina primero. El regreso al login no depende
    //    de la respuesta del servidor.
    try {
      await _authLocal.clearActiveSession();
    } catch (_) {}

    if (!mounted) return;

    // 2) Mostramos el login inmediatamente, PERO conservamos temporalmente
    //    el BlocProvider durante este frame. Algunas rutas/widgets anteriores
    //    todavía pueden estar terminando de desmontarse y podrían intentar
    //    leer KomandaBloc. Retirarlo aquí provoca "Provider not found" y
    //    termina dejando Flutter Web en una pantalla gris.
    setState(() {
      _session = null;
      _bootError = null;
      _booting = false;
      _loginGeneration++;
    });

    // 3) Después de que Flutter terminó el frame donde desmontó el Navigator
    //    autenticado, retiramos y cerramos el Bloc de la sesión vieja.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_session == null && identical(_bloc, oldBloc)) {
        setState(() {
          _bloc = null;
          _repository = null;
        });
      }

      Future<void>(() async {
        try {
          await oldBloc?.close();
        } catch (_) {}

        // Logout remoto de mejor esfuerzo. Se hace fuera de la transición
        // visual para que una API lenta nunca bloquee el login.
        try {
          await remote?.logout().timeout(const Duration(seconds: 5));
        } catch (_) {}
      });
    });
  }

  Future<void> _updateSession(KomandaSession session) async {
    await _authLocal.saveSession(session);
    if (!mounted) return;
    setState(() {
      _session = session;
    });
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: Text('Actualizando...', style: TextStyle(fontWeight: FontWeight.w800))));
    }

    if (_session == null) {
      final login = KomandaLoginPage(
        key: ValueKey('komanda-login-$_loginGeneration'),
        onLogin: _login,
      );

      // Durante el primer frame posterior al logout mantenemos disponible
      // el provider antiguo para cualquier widget/ruta que todavía se esté
      // desmontando. El login NO depende del Bloc y en el siguiente frame
      // _logout() lo retira definitivamente.
      if (_bloc != null) {
        return BlocProvider.value(
          value: _bloc!,
          child: login,
        );
      }

      return login;
    }

    if (_bloc == null || _repository == null) {
      return const Scaffold(
        body: Center(child: Text('Actualizando...', style: TextStyle(fontWeight: FontWeight.w800))),
      );
    }

    return BlocProvider.value(
      value: _bloc!,
      child: Navigator(
        key: ValueKey('komanda-${_session!.userId}-${_session!.token}'),
        initialRoute: _resolveInitialRoute(widget.initialRoute),
        onGenerateRoute: _generateKomandaRoute,
      ),
    );
  }

  String _resolveInitialRoute(String? route) {
    if (route == null || route == RouteNames.komanda) {
      return RouteNames.komandaDashboard;
    }
    return route;
  }


  Widget _guard(bool allowed, Widget child) {
    if (allowed) return child;
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Tu perfil no tiene permiso para abrir esta sección.', textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Route<dynamic> _generateKomandaRoute(RouteSettings settings) {
    final Widget page;

    switch (settings.name) {
      case RouteNames.komandaNewOrderTable:
      case RouteNames.komandaNewOrderProducts:
      case RouteNames.komandaOrderSummary:
        page = _guard(
          KomandaPermissions.canCreateOrders(_session!.role),
          KomandaOrderFlowPage(
            currentUserId: _session!.userId,
            currentUserName: _session!.name,
            currentUserRole: _session!.role,
            restaurantId: _session!.restaurantId,
          ),
        );
        break;
      case RouteNames.komandaChefOrders:
        page = settings.arguments is KomandaOrder
            ? KomandaDetailPage(order: settings.arguments as KomandaOrder)
            : _guard(KomandaPermissions.canUseKitchen(_session!.role), KomandaChefOrdersPage(remote: _repository!.remoteDataSource));
        break;
      case RouteNames.komandaWaiterCalls:
        page = _guard(KomandaPermissions.canUseWaiterArea(_session!.role), const KomandaWaiterCallsPage());
        break;
      case RouteNames.komandaHistory:
        page = _guard(KomandaPermissions.canViewHistory(_session!.role), KomandaHistoryPage());
        break;
      case '/komanda/tables-overview':
        page = _guard(_session!.restaurantId != '2' && KomandaPermissions.isAdmin(_session!.role), const KomandaTablesOverviewPage());
        break;
      case '/komanda/waiters':
        page = _guard(_session!.restaurantId != '2' && KomandaPermissions.canUseWaiterArea(_session!.role), const KomandaWaitersPage());
        break;
      case '/komanda/categories':
        page = _guard(KomandaPermissions.canManageCatalog(_session!.role), const KomandaCategoriesPage());
        break;
      case '/komanda/tables-admin':
        page = _guard(_session!.restaurantId != '2' && KomandaPermissions.canManageRestaurant(_session!.role), const KomandaTablesAdminPage());
        break;
      case '/komanda/checkout':
        page = _guard(KomandaPermissions.canCharge(_session!.role), const KomandaCheckoutPage());
        break;
      case '/komanda/cash-close':
        page = _guard(KomandaPermissions.isAdmin(_session!.role), const KomandaCashClosePage());
        break;
      case '/komanda/payments':
        page = _guard(KomandaPermissions.canCharge(_session!.role), const KomandaPaymentsPage());
        break;
      case '/komanda/performance':
        page = _guard(KomandaPermissions.isAdmin(_session!.role), const KomandaPerformancePage());
        break;
      case '/komanda/finances':
        page = _guard(KomandaPermissions.isAdmin(_session!.role), KomandaFinancesPage(remote: _repository!.remoteDataSource));
        break;
      case '/komanda/order-status':
        page = _guard(KomandaPermissions.canViewOrderStatus(_session!.role), const KomandaPublicOrderStatusPage());
        break;
      case '/komanda/users':
        page = _guard(KomandaPermissions.isAdmin(_session!.role), KomandaUsersAdminPage(remote: _repository!.remoteDataSource));
        break;
      case '/komanda/profile':
        page = KomandaProfilePage(
          session: _session!,
          remote: _repository!.remoteDataSource,
          onSessionUpdated: _updateSession,
          onLogout: _logout,
        );
        break;
      case RouteNames.komandaDashboard:
      default:
        page = KomandaDashboardPage(
          username: _session?.name.isNotEmpty == true
              ? _session!.name
              : (_session?.username ?? ''),
          role: _session!.role,
          restaurantId: _session!.restaurantId,
          remote: _repository!.remoteDataSource,
          onLogout: _logout,
        );
        break;
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
