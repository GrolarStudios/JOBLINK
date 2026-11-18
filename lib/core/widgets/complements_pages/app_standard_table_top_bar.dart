import 'package:flutter/material.dart';

import 'app_standard_table_widgets.dart';

class AppStandardTableTopBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool searchExpanded;
  final bool isRefreshing;
  final String searchHintText;
  final String totalTitle;
  final int totalCount;
  final VoidCallback onToggleSearch;
  final VoidCallback? onRefresh;
  final ValueChanged<String> onSearchChanged;
  final Widget? rightActions;
  final bool showInfoCards;

  const AppStandardTableTopBar({
    super.key,
    required this.searchController,
    required this.searchExpanded,
    required this.isRefreshing,
    required this.searchHintText,
    required this.totalTitle,
    required this.totalCount,
    required this.onToggleSearch,
    required this.onRefresh,
    required this.onSearchChanged,
    this.rightActions,
    this.showInfoCards = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1180;
        final leftIsland = _buildSearchActionsIsland();
        final rightIsland = AppStandardActionsIsland(
          child: rightActions ?? const SizedBox(height: 38, width: double.infinity),
        );
        final infoCards = AppStandardActionsIsland(
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppStandardInfoCard(
                  title: totalTitle,
                  value: totalCount.toString(),
                ),
              ],
            ),
          ),
        );

        if (!showInfoCards) {
          return leftIsland;
        }

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftIsland),
                  const SizedBox(width: 4),
                  Expanded(child: rightIsland),
                ],
              ),
              const SizedBox(height: 4),
              infoCards,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftIsland),
                  const SizedBox(width: 4),
                  Expanded(child: rightIsland),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(flex: 5, child: infoCards),
          ],
        );
      },
    );
  }

  Widget _buildSearchActionsIsland() {
    return AppStandardActionsIsland(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppStandardEmojiButton(
            emoji: searchExpanded ? '❌' : '🔎',
            tooltip: searchExpanded ? 'Ocultar búsqueda' : 'Buscar',
            onPressed: onToggleSearch,
          ),
          _buildSearchField(),
          AppStandardEmojiButton(
            emoji: isRefreshing ? '⏳' : '🔄',
            tooltip: isRefreshing ? 'Actualizando...' : 'Actualizar',
            onPressed: isRefreshing ? null : onRefresh,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: !searchExpanded
          ? const SizedBox.shrink()
          : SizedBox(
        key: const ValueKey('standard_search_input'),
        width: 280,
        child: TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: searchHintText,
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Center(
              widthFactor: 1,
              child: Text('🔎', style: TextStyle(fontSize: 18)),
            ),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
              tooltip: 'Limpiar búsqueda',
              icon: const Text('❌', style: TextStyle(fontSize: 17)),
              onPressed: () {
                searchController.clear();
                onSearchChanged('');
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF111827), width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}