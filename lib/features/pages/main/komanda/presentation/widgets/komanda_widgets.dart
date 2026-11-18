import 'package:flutter/material.dart';
import '../shared/widgets/komanda_touch_keyboard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/routes/route_names.dart';
import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../domain/entities/komanda_entities.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';

class KomandaPhoneFrame extends StatelessWidget {
  final Widget child;
  final bool useGlobalLoading;

  const KomandaPhoneFrame({
    super.key,
    required this.child,
    this.useGlobalLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    Widget content = Stack(
      children: [
        Positioned.fill(child: child),
      ],
    );

    if (useGlobalLoading) {
      content = BlocBuilder<KomandaBloc, KomandaState>(
        buildWhen: (previous, current) =>
            previous.status != current.status,
        builder: (context, state) {
          final isLoading =
              state.status == KomandaStatus.loading ||
              state.status == KomandaStatus.saving;

          const loadingText = 'Actualizando...';

          return Stack(
            children: [
              Positioned.fill(child: child),
              if (isLoading)
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      color: Colors.white.withOpacity(.78),
                      alignment: Alignment.center,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Text(
                          loadingText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: KomandaTheme.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    final baseTheme = Theme.of(context);
    return Theme(
      data: baseTheme.copyWith(
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titleTextStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: KomandaTheme.text),
          contentTextStyle: const TextStyle(fontSize: 14, color: KomandaTheme.text, height: 1.4),
        ),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
          foregroundColor: KomandaTheme.primary,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        )),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: KomandaTheme.primary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        )),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
          backgroundColor: KomandaTheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          side: const BorderSide(color: KomandaTheme.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        )),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KomandaTheme.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KomandaTheme.border)),
        ),
      ),
      child: Scaffold(
      backgroundColor: KomandaTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width >= 1200 ? 1180 : (width >= 760 ? 920 : double.infinity),
            ),
            child: content,
          ),
        ),
      ),
      ),
    );
  }
}

class KomandaHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool menu;
  final bool showBack;
  final bool bell;
  final int bellCount;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;
  final bool showRefresh;
  final bool tools;
  final VoidCallback? onToolsTap;
  final VoidCallback? onRefresh;
  const KomandaHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.menu = false,
    this.showBack = true,
    this.bell = false,
    this.bellCount = 0,
    this.onLeadingTap,
    this.onTrailingTap,
    this.showRefresh = true,
    this.tools = false,
    this.onToolsTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Regresar',
              onPressed: onLeadingTap ?? () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KomandaTheme.text),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Column(
              children: [
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
                if (subtitle != null) Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: KomandaTheme.purple)),
              ],
            ),
          ),
          if (showRefresh)
            IconButton(
              tooltip: 'Actualizar',
              onPressed: onRefresh ?? () => context.read<KomandaBloc>().add(const KomandaRefreshed()),
              icon: const Icon(Icons.refresh_rounded, color: KomandaTheme.text, size: 25),
            ),
        ],
      ),
    );
  }
}

class _HeaderMenuItem extends StatelessWidget {
  final IconData icon; final String text;
  const _HeaderMenuItem({required this.icon, required this.text});
  @override Widget build(BuildContext context)=>Row(children:[Icon(icon,color:KomandaTheme.purple,size:20),const SizedBox(width:10),Text(text,style:const TextStyle(fontWeight:FontWeight.w800))]);
}

class KomandaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const KomandaCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: padding,
    decoration: KomandaTheme.cardDecoration(),
    child: child,
  );
}

class KChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  const KChip({super.key, required this.text, this.color = KomandaTheme.purple, this.icon, this.onTap, this.selected = true});
  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(.12) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color.withOpacity(.22) : KomandaTheme.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 6)],
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
    return onTap == null ? content : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: content);
  }
}

class ProductTile extends StatelessWidget {
  final KomandaProduct product;
  final bool image;
  final bool controls;
  final bool status;
  final bool verticalLayout;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const ProductTile({
    super.key,
    required this.product,
    this.image = false,
    this.controls = false,
    this.status = false,
    this.verticalLayout = false,
    this.onAdd,
    this.onRemove,
  });

  Widget _productImage() => Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.image.isEmpty
                ? Container(
                    width: 46,
                    height: 46,
                    color: KomandaTheme.purple.withOpacity(.10),
                    child: const Icon(Icons.restaurant_menu, color: KomandaTheme.purple),
                  )
                : Image.asset(
                    product.image,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 46,
                      height: 46,
                      color: KomandaTheme.purple.withOpacity(.10),
                      child: const Icon(Icons.restaurant_menu, color: KomandaTheme.purple),
                    ),
                  ),
          ),
          Positioned(
            right: -7,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: KomandaTheme.purple,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${product.quantity}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      );

  Widget _info() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: KomandaTheme.text),
          ),
          if (product.note.isNotEmpty)
            Text(
              product.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KomandaTheme.softText),
            ),
          if (image) ...[
            const SizedBox(height: 3),
            Text(
              '${komandaMoney(product.price)} c/u',
              style: const TextStyle(fontWeight: FontWeight.w900, color: KomandaTheme.purple),
            ),
          ],
        ],
      );

  Widget _controls() => Container(
        decoration: BoxDecoration(
          border: Border.all(color: KomandaTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: onRemove, icon: const Icon(Icons.remove), visualDensity: VisualDensity.compact),
            Text('${product.quantity}', style: const TextStyle(fontWeight: FontWeight.w900)),
            IconButton(onPressed: onAdd, icon: const Icon(Icons.add), visualDensity: VisualDensity.compact),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (verticalLayout) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image) ...[_productImage(), const SizedBox(width: 12)],
                Expanded(child: _info()),
              ],
            ),
            const SizedBox(height: 12),
            if (controls)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${product.quantity} ${product.quantity == 1 ? 'seleccionado' : 'seleccionados'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KomandaTheme.softText),
                    ),
                  ),
                  _controls(),
                ],
              )
            else if (status)
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 15, color: KomandaTheme.orange),
                  SizedBox(width: 4),
                  Text('En preparación', style: TextStyle(color: KomandaTheme.orange, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  komandaMoney(product.total),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: KomandaTheme.text),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (image) _productImage()
          else
            CircleAvatar(
              backgroundColor: KomandaTheme.purple.withOpacity(.10),
              child: Text('${product.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, color: KomandaTheme.text)),
            ),
          const SizedBox(width: 14),
          Expanded(child: _info()),
          if (controls) _controls(),
          const SizedBox(width: 10),
          if (status)
            const Row(
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: KomandaTheme.orange),
                SizedBox(width: 4),
                Text('En preparación', style: TextStyle(color: KomandaTheme.orange, fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            )
          else
            Text(komandaMoney(product.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: KomandaTheme.text)),
        ],
      ),
    );
  }
}

class BottomNavMock extends StatelessWidget {
  final int index;
  const BottomNavMock({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      Icons.home_rounded,
      Icons.point_of_sale_rounded,
    ];
    const labels = <String>['Inicio', 'Corte'];

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16)],
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: InkWell(
              onTap: selected ? null : () => _openItem(context, i),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icons[i], color: selected ? KomandaTheme.purple : KomandaTheme.softText),
                  const SizedBox(height: 2),
                  Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: selected ? KomandaTheme.purple : KomandaTheme.softText, fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _openItem(BuildContext context, int itemIndex) {
    switch (itemIndex) {
      case 0: Navigator.pushNamed(context, RouteNames.komandaDashboard); break;
      case 1: Navigator.pushNamed(context, '/komanda/cash-close'); break;
    }
  }
}

class KomandaSearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;
  const KomandaSearchField({super.key, required this.onChanged, this.hintText = 'Buscar...', this.controller});

  @override
  State<KomandaSearchField> createState() => _KomandaSearchFieldState();
}

class _KomandaSearchFieldState extends State<KomandaSearchField> {
  late final TextEditingController _localController;
  @override
  void initState() {
    super.initState();
    _localController = TextEditingController();
  }
  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final fieldController = widget.controller ?? _localController;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: fieldController,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            if (fieldController.text.isNotEmpty) IconButton(
              tooltip: 'Limpiar búsqueda',
              onPressed: () { fieldController.clear(); widget.onChanged(''); setState(() {}); },
              icon: const Icon(Icons.close),
            ),
            KomandaTouchKeyboard.button(context, fieldController, onChanged: (value) {
              widget.onChanged(value);
              if (mounted) setState(() {});
            }),
          ]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}


class KomandaSearchRefreshBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;
  final TextEditingController? controller;
  final bool refreshing;

  const KomandaSearchRefreshBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.onRefresh,
    this.controller,
    this.refreshing = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller == null || controller!.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      controller!.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}
