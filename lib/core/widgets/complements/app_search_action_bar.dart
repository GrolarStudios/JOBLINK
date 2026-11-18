import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSearchActionItem {
  final String id;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isVisible;
  final FocusNode? focusNode;

  const AppSearchActionItem({
    required this.id,
    this.focusNode,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isVisible = true,
  });
}

class AppSearchActionBar extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final List<AppSearchActionItem> actions;

  final TextEditingController? extraController;
  final FocusNode? extraFocusNode;
  final String? extraHint;
  final VoidCallback? onExtraSubmitted;
  final bool showExtraInput;
  final TextInputType extraKeyboardType;
  final List<TextInputFormatter>? extraInputFormatters;

  final AppSearchActionItem? primaryInlineAction;

  final bool collapsibleSearch;
  final bool searchInitiallyExpanded;

  const AppSearchActionBar({
    super.key,
    required this.searchController,
    required this.actions,
    this.onSearchChanged,
    this.searchHint = 'Buscar...',
    this.extraController,
    this.extraFocusNode,
    this.extraHint,
    this.onExtraSubmitted,
    this.showExtraInput = false,
    this.extraKeyboardType = TextInputType.text,
    this.extraInputFormatters,
    this.primaryInlineAction,
    this.collapsibleSearch = false,
    this.searchInitiallyExpanded = true,
  });

  @override
  State<AppSearchActionBar> createState() => _AppSearchActionBarState();
}

class _AppSearchActionBarState extends State<AppSearchActionBar> {
  late bool _searchExpanded;

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _searchExpanded = widget.searchInitiallyExpanded;

    widget.searchController.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant AppSearchActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_refresh);
      widget.searchController.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleSearch() {
    setState(() {
      _searchExpanded = !_searchExpanded;
    });

    if (_searchExpanded) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      widget.searchController.clear();
      widget.onSearchChanged?.call('');
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_refresh);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visibleActions =
    widget.actions.where((e) => e.isVisible).toList();

    final isInlineVisible =
        widget.primaryInlineAction?.isVisible ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          final searchWidth =
          isMobile ? constraints.maxWidth : 280.0;

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [

              // 🔥 INPUT INLINE
              if (widget.showExtraInput)
                _buildInlineAmountGroup(theme),

              // 🔥 BOTON INLINE
              if (widget.showExtraInput && isInlineVisible)
                _buildActionButton(
                  theme,
                  widget.primaryInlineAction!,
                  compact: true,
                ),

              // 🔥 BOTONES
              ...visibleActions.map(
                    (action) => _buildActionButton(theme, action),
              ),

              // 🔥 INLINE SIN INPUT
              if (!widget.showExtraInput && isInlineVisible)
                _buildActionButton(
                  theme,
                  widget.primaryInlineAction!,
                  compact: true,
                ),

              // 🔥 BUSQUEDA SIEMPRE AL FINAL
              if (widget.collapsibleSearch)
                _buildSearchToggleButton(),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                width: widget.collapsibleSearch
                    ? (_searchExpanded ? searchWidth : 0)
                    : searchWidth,
                height: 46,
                child: (!_searchExpanded &&
                    widget.collapsibleSearch)
                    ? const SizedBox.shrink()
                    : _buildCompactSearchField(theme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchToggleButton() {
    return Tooltip(
      message: _searchExpanded
          ? 'Cerrar búsqueda'
          : 'Buscar',
      child: Material(
        color: const Color(0xFF475569),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _toggleSearch,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              _searchExpanded
                  ? Icons.close_rounded
                  : Icons.search_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSearchField(ThemeData theme) {
    return TextField(
      controller: widget.searchController,
      focusNode: _searchFocusNode,
      onChanged: widget.onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.searchHint,
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Colors.grey.shade600,
          size: 20,
        ),
        suffixIcon: widget.searchController.text.isNotEmpty
            ? IconButton(
          tooltip: 'Limpiar',
          icon: Icon(
            Icons.close_rounded,
            color: Colors.grey.shade600,
            size: 18,
          ),
          onPressed: () {
            widget.searchController.clear();
            widget.onSearchChanged?.call('');
          },
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.45),
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineAmountGroup(
      ThemeData theme, {
        bool isMobile = false,
      }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.withOpacity(0.16),
        ),
      ),
      child: SizedBox(
        width: isMobile ? 95 : 90,
        child: TextField(
          controller: widget.extraController,
          focusNode: widget.extraFocusNode,
          keyboardType: widget.extraKeyboardType,
          textAlign: TextAlign.center,
          inputFormatters: widget.extraInputFormatters,
          onSubmitted: (_) => widget.onExtraSubmitted?.call(),
          decoration: InputDecoration(
            hintText: widget.extraHint ?? '',
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.80),
                width: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      ThemeData theme,
      AppSearchActionItem action, {
        bool compact = false,
      }) {
    final bg =
        action.backgroundColor ?? theme.colorScheme.primary;

    final fg =
        action.foregroundColor ??
            theme.colorScheme.onPrimary;

    final size = compact ? 42.0 : 46.0;

    final radius = compact ? 12.0 : 14.0;

    return Tooltip(
      message: action.tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          focusNode: action.focusNode,
          onTap: action.onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              action.icon,
              color: fg,
              size: compact ? 20 : 22,
            ),
          ),
        ),
      ),
    );
  }
}