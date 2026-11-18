import 'package:flutter/material.dart';

import '../../core/komanda_theme.dart';
import '../widgets/komanda_widgets.dart';

class KomandaLoginPage extends StatefulWidget {
  final Future<KomandaLoginResult> Function(String username, String password)
      onLogin;

  const KomandaLoginPage({
    super.key,
    required this.onLogin,
  });

  @override
  State<KomandaLoginPage> createState() => _KomandaLoginPageState();
}

class KomandaLoginResult {
  final bool success;
  final bool offline;
  final String? message;

  const KomandaLoginResult({
    required this.success,
    this.offline = false,
    this.message,
  });
}

class _KomandaLoginPageState extends State<KomandaLoginPage> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _userFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (_loading) return;
    if (_user.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Ingresa tu usuario y contraseña.');
      if (_user.text.trim().isEmpty) _userFocus.requestFocus();
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.onLogin(_user.text.trim(), _password.text);
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _loading = false;
          _error = result.message ?? 'Usuario o contraseña incorrectos.';
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No fue posible iniciar sesión. Intenta nuevamente.';
      });
    }
  }

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    _userFocus.dispose();
    super.dispose();
  }

  Widget _brand({bool expanded = false}) => Column(
    crossAxisAlignment: expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 68, height: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF9B39), KomandaTheme.purple]),
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [BoxShadow(color: Color(0x35EA6B0A), blurRadius: 22, offset: Offset(0, 9))],
        ),
        child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 33),
      ),
      const SizedBox(height: 20),
      Text('Komanda', style: TextStyle(
        color: expanded ? Colors.white : KomandaTheme.text,
        fontSize: expanded ? 36 : 27, fontWeight: FontWeight.w900,
        letterSpacing: -.8,
      )),
      const SizedBox(height: 9),
      Text('Todo tu restaurante, en un solo lugar.',
        textAlign: expanded ? TextAlign.start : TextAlign.center,
        style: TextStyle(color: expanded ? const Color(0xFFFFE5CF) : KomandaTheme.softText,
          fontSize: expanded ? 17 : 14, height: 1.45)),
    ],
  );

  Widget _form({required bool showBrand}) => Container(
    constraints: const BoxConstraints(maxWidth: 440),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFF1E7DF)),
      boxShadow: const [BoxShadow(color: Color(0x100F254A), blurRadius: 35, offset: Offset(0, 14))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (showBrand) ...[_brand(), const SizedBox(height: 30)],
      const Text('Bienvenido de nuevo', style: TextStyle(
        color: KomandaTheme.text, fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      const Text('Ingresa tus datos para comenzar tu jornada.',
        style: TextStyle(color: KomandaTheme.softText, fontSize: 14)),
      const SizedBox(height: 27),
      const Text('Usuario', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      TextField(
        controller: _user,
        focusNode: _userFocus,
        enabled: !_loading,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username],
        onChanged: (_) { if (_error != null) setState(() => _error = null); },
        decoration: InputDecoration(
          hintText: 'Tu usuario',
          prefixIcon: const Icon(Icons.person_outline_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const SizedBox(height: 19),
      const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      TextField(
        controller: _password,
        enabled: !_loading,
        obscureText: _obscure,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => _login(),
        onChanged: (_) { if (_error != null) setState(() => _error = null); },
        decoration: InputDecoration(
          hintText: 'Ingresa tu contraseña',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          ),
        ),
      ),
      if (_error != null) Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF1EF),
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318), size: 20),
            const SizedBox(width: 9),
            Expanded(child: Text(_error!, style: const TextStyle(
              color: Color(0xFFB42318), fontWeight: FontWeight.w600, fontSize: 13))),
          ]),
        ),
      ),
      const SizedBox(height: 25),
      SizedBox(height: 54, child: FilledButton(
        onPressed: _loading ? null : _login,
        style: FilledButton.styleFrom(
          backgroundColor: KomandaTheme.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(width: 12), Icon(Icons.arrow_forward_rounded, size: 20),
            ]),
      )),
      const SizedBox(height: 18),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock_outline_rounded, size: 15, color: KomandaTheme.softText),
        SizedBox(width: 6),
        Flexible(child: Text('Acceso seguro para tu equipo',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: KomandaTheme.softText))),
      ]),
    ]),
  );

  @override
  Widget build(BuildContext context) => KomandaPhoneFrame(
    useGlobalLoading: false,
    child: LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      return Container(
        color: const Color(0xFFFFF8F2),
        child: SafeArea(
          child: Row(children: [
            if (wide) Expanded(
              flex: 11,
              child: Container(
                margin: const EdgeInsets.all(18),
                padding: const EdgeInsets.all(54),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFFC9437), Color(0xFFEA6B0A), Color(0xFFB84A00)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _brand(expanded: true),
                  const Spacer(),
                  const Icon(Icons.auto_awesome_rounded, size: 38, color: Colors.white),
                  const SizedBox(height: 18),
                  const Text('Una operación más ágil.\\nUn mejor servicio.',
                    style: TextStyle(color: Colors.white, fontSize: 32,
                      fontWeight: FontWeight.w900, height: 1.22)),
                  const SizedBox(height: 16),
                  const Text('Pedidos, cocina y caja conectados para que tu equipo se enfoque en atender.',
                    style: TextStyle(color: Color(0xFFFFE5CF), fontSize: 16, height: 1.5)),
                ]),
              ),
            ),
            Expanded(
              flex: wide ? 10 : 1,
              child: Center(child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 450 ? 16 : 28,
                  vertical: 28,
                ),
                child: Align(alignment: Alignment.center,
                  child: _form(showBrand: !wide)),
              )),
            ),
          ]),
        ),
      );
    }),
  );
}
