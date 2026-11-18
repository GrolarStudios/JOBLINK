import 'package:flutter/material.dart';

import '../../../../../../core/utils/colors/gs_colors.dart';
import '../../../../../../core/widgets/complements/app_search_action_bar.dart';
import '../../../../../../core/widgets/complements/app_table_actions_panel.dart';
import 'faltantes_precios_banner.dart';

class FaltantesPreciosTopBar extends StatelessWidget {
  final TextEditingController searchController;
  final String folio;
  final String providerName;
  final String estatus;
  final int productos;
  final bool refreshing;
  final bool saving;
  final bool isAuctionClosed;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReload;
  final VoidCallback onSave;

  const FaltantesPreciosTopBar({
    super.key,
    required this.searchController,
    required this.folio,
    required this.providerName,
    required this.estatus,
    required this.productos,
    required this.refreshing,
    required this.saving,
    required this.isAuctionClosed,
    required this.onSearchChanged,
    required this.onReload,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaltantesPreciosBanner(
          folio: folio,
          providerName: providerName,
          estatus: estatus,
          productos: productos,
        ),

        const SizedBox(height: 10),

        AppTableActionsPanel(
          child: AppSearchActionBar(
            searchController: searchController,
            onSearchChanged: onSearchChanged,
            searchHint: 'Buscar productos...',

            // 🔥 NUEVO
            collapsibleSearch: true,
            searchInitiallyExpanded: false,

            actions: [
              AppSearchActionItem(
                id: 'reload',
                icon: refreshing
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                tooltip: refreshing
                    ? 'Recargando...'
                    : 'Actualizar',
                onPressed: () {
                  if (refreshing || saving) return;
                  onReload();
                },

                // 🔥 COLOR AZUL ESTANDAR
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),

              AppSearchActionItem(
                id: 'save',
                icon: saving
                    ? Icons.hourglass_top_rounded
                    : Icons.save_rounded,
                tooltip: saving
                    ? 'Guardando...'
                    : 'Guardar cotización',
                onPressed: () {
                  if (saving || refreshing || isAuctionClosed) return;
                  onSave();
                },

                // 🔥 COLOR TEAL EMPRESARIAL
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
