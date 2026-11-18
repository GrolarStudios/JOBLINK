import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppStandardTableInputType {
  quantity,
  money,
}

class AppStandardTableInputCell extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final AppStandardTableInputType type;
  final bool enabled;
  final bool isActive;
  final bool isEdited;
  final bool wasTouched;
  final bool isSaving;
  final String? hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppStandardTableInputCell({
    super.key,
    required this.controller,
    required this.type,
    this.focusNode,
    this.enabled = true,
    this.isActive = false,
    this.isEdited = false,
    this.wasTouched = false,
    this.isSaving = false,
    this.hintText,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AppStandardTableInputCell> createState() =>
      _AppStandardTableInputCellState();
}

class _AppStandardTableInputCellState extends State<AppStandardTableInputCell> {
  bool _hovered = false;
  late final FocusNode _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode;

  bool get _isMoney => widget.type == AppStandardTableInputType.money;

  @override
  void initState() {
    super.initState();
    _ownedFocusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppStandardTableInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldFocusNode = oldWidget.focusNode ?? _ownedFocusNode;
    final newFocusNode = widget.focusNode ?? _ownedFocusNode;

    if (oldFocusNode != newFocusNode) {
      oldFocusNode.removeListener(_handleFocusChanged);
      newFocusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;

    setState(() {});

    if (!_focusNode.hasFocus) {
      _normalizeText();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_focusNode.hasFocus) return;
      _selectAll();
    });
  }

  void _selectAll() {
    if (widget.controller.text.isEmpty) return;

    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _moneyOnly(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final firstDot = clean.indexOf('.');

    if (firstDot == -1) return clean;

    final before = clean.substring(0, firstDot + 1);
    final after = clean
        .substring(firstDot + 1)
        .replaceAll('.', '');

    return before + after;
  }

  String _normalizeQuantity(String value) {
    final clean = _digitsOnly(value);
    if (clean.isEmpty) return '';

    final parsed = num.tryParse(clean);
    if (parsed == null || parsed <= 0) return '';

    return parsed.toInt().toString();
  }

  String _normalizeMoney(String value) {
    final clean = _moneyOnly(value);
    if (clean.isEmpty) return '';

    final parsed = num.tryParse(clean);
    if (parsed == null || parsed <= 0) return '';

    return parsed.toStringAsFixed(2);
  }

  void _normalizeText() {
    final normalized = _isMoney
        ? _normalizeMoney(widget.controller.text)
        : _normalizeQuantity(widget.controller.text);

    if (widget.controller.text == normalized) return;

    widget.controller.text = normalized;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
  }

  Color get _fillColor {
    if (!widget.enabled) return const Color(0xFFE7E6E6);
    if (widget.isActive || _focusNode.hasFocus) return const Color(0xFFFFF2CC);
    if (widget.isEdited) return const Color(0xFFE2F0D9);
    if (widget.wasTouched) return const Color(0xFFFCE4D6);
    if (_hovered) return const Color(0xFFDDEBF7);

    return Colors.white;
  }

  Color get _borderColor {
    if (widget.isActive || _focusNode.hasFocus) return const Color(0xFFBF9000);
    if (widget.isEdited) return const Color(0xFF70AD47);
    if (widget.wasTouched) return const Color(0xFFED7D31);
    if (_hovered) return const Color(0xFF5B9BD5);

    return const Color(0xFFD9E2F3);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 86;
        final enabled = widget.enabled && !widget.isSaving;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(
              decimal: _isMoney,
            ),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                _isMoney ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
              ),
            ],
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              height: 1,
              fontWeight: FontWeight.w900,
              color: widget.isEdited
                  ? const Color(0xFF166534)
                  : const Color(0xFF334155),
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _fillColor,
              hintText: widget.hintText ?? (_isMoney ? '0.00' : '0'),
              hintStyle: TextStyle(
                fontSize: compact ? 9 : 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
              suffixIcon: widget.isSaving
                  ? const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 22,
                minHeight: 22,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 3 : 8,
                vertical: compact ? 7 : 9,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _borderColor,
                  width: widget.isEdited ||
                      widget.wasTouched ||
                      widget.isActive ||
                      _focusNode.hasFocus
                      ? 1.4
                      : 1.1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFBF9000),
                  width: 1.8,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            onTap: () {
              widget.onTap?.call();
              _selectAll();
            },
            onChanged: (value) {
              final clean = _isMoney ? _moneyOnly(value) : _digitsOnly(value);

              if (clean != value) {
                widget.controller.text = clean;
                widget.controller.selection = TextSelection.collapsed(
                  offset: clean.length,
                );
              }

              widget.onChanged?.call(clean);
            },
            onSubmitted: (value) {
              _normalizeText();
              widget.onSubmitted?.call(widget.controller.text);
            },
          ),
        );
      },
    );
  }
}
