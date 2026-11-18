import 'package:flutter/material.dart';

import '../../../../../../core/utils/colors/gs_colors.dart';
import '../../../../../../core/widgets/complements/app_search_action_bar.dart';
import '../../../../../../core/widgets/complements/app_table_actions_panel.dart';

class ProviderViewTopBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isRefreshing;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReload;

  const ProviderViewTopBar({
    super.key,
    required this.searchController,
    required this.isRefreshing,
    required this.onSearchChanged,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return AppTableActionsPanel(
      child: AppSearchActionBar(
        searchController: searchController,
        onSearchChanged: onSearchChanged,
        searchHint: 'Buscar subastas...',

        // 🔥 BUSQUEDA EXPANDIBLE
        collapsibleSearch: true,
        searchInitiallyExpanded: false,

        actions: [
          AppSearchActionItem(
            id: 'reload',
            icon: isRefreshing
                ? Icons.hourglass_top_rounded
                : Icons.refresh_rounded,
            tooltip: isRefreshing
                ? 'Recargando...'
                : 'Actualizar',
            onPressed: () {
              if (isRefreshing) return;
              onReload();
            },

            // 🔥 AZUL ESTÁNDAR
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}