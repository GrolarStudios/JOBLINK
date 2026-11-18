import 'package:flutter/material.dart';

/// Barra superior estándar para las 3 islas del módulo.
///
/// Estructura desktop:
/// [isla izquierda 25%] [isla centro 25%] [isla info 50%]
///
/// En móvil/tablet se acomoda en columna.
///
/// IMPORTANTE:
/// No usamos CrossAxisAlignment.stretch en desktop porque puede romper el alto
/// cuando esta barra está dentro de un Column y hacer que desaparezcan
/// las otras islas o la tabla.
class AppStandardThreeIslandsTopBar extends StatelessWidget {
  final Widget leftIsland;
  final Widget centerIsland;
  final Widget infoIsland;
  final double gap;
  final double breakpoint;

  const AppStandardThreeIslandsTopBar({
    super.key,
    required this.leftIsland,
    required this.centerIsland,
    required this.infoIsland,
    this.gap = 10,
    this.breakpoint = 1180,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < breakpoint;

        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftIsland,
              SizedBox(height: gap),
              centerIsland,
              SizedBox(height: gap),
              infoIsland,
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 25, child: leftIsland),
            SizedBox(width: gap),
            Expanded(flex: 25, child: centerIsland),
            SizedBox(width: gap),
            Expanded(flex: 50, child: infoIsland),
          ],
        );
      },
    );
  }
}

/// Contenedor visual estándar para cualquier isla.
/// Cambia aquí padding, radius, borde, sombra o altura y aplica a todas.
class AppStandardTopIsland extends StatelessWidget {
  final Widget child;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const AppStandardTopIsland({
    super.key,
    required this.child,
    this.minHeight = 62,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.alignment = Alignment.centerLeft,
  });

  const AppStandardTopIsland.empty({
    super.key,
    this.minHeight = 62,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.alignment = Alignment.centerLeft,
  }) : child = const SizedBox(width: double.infinity, height: 42);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Container(
        width: double.infinity,
        padding: padding,
        alignment: alignment,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class AppStandardTopIslandAction {
  final String emoji;
  final String title;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppStandardTopIslandAction({
    required this.emoji,
    required this.title,
    required this.onTap,
    this.backgroundColor,
  });
}

/// Botón estándar. Solo mandas emoji, título y función.
class AppStandardTopIslandButton extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppStandardTopIslandButton({
    super.key,
    required this.emoji,
    required this.title,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Tooltip(
      message: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class AppStandardTopActionsIsland extends StatelessWidget {
  final List<AppStandardTopIslandAction> actions;
  final List<Widget> children;
  final WrapAlignment alignment;

  const AppStandardTopActionsIsland({
    super.key,
    this.actions = const [],
    this.children = const [],
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return AppStandardTopIsland(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final action in actions)
            AppStandardTopIslandButton(
              emoji: action.emoji,
              title: action.title,
              onTap: action.onTap,
              backgroundColor: action.backgroundColor,
            ),
          ...children,
        ],
      ),
    );
  }
}

class AppStandardTopInfoItem {
  final String title;
  final String value;
  final double width;

  const AppStandardTopInfoItem({
    required this.title,
    required this.value,
    this.width = 92,
  });
}

class AppStandardTopInfoIsland extends StatelessWidget {
  final List<AppStandardTopInfoItem> items;
  final MainAxisAlignment mainAxisAlignment;

  const AppStandardTopInfoIsland({
    super.key,
    required this.items,
    this.mainAxisAlignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return AppStandardTopIsland(
      alignment: Alignment.centerRight,
      child: Align(
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: mainAxisAlignment,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                AppStandardTopInfoCard(item: items[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Carta de información: valor arriba, título abajo y ambos centrados.
class AppStandardTopInfoCard extends StatelessWidget {
  final AppStandardTopInfoItem item;

  const AppStandardTopInfoCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: item.width,
      height: 42,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}