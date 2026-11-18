import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppStandardQuoteInputType {
  quantity,
  money,
}

class AppStandardQuoteInputCell extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AppStandardQuoteInputType type;
  final bool enabled;
  final String hintText;
  final bool wasEdited;
  final bool wasTouched;
  final bool wasPrefilled;
  final VoidCallback? onMoveNext;
  final VoidCallback? onMovePrevious;
  final ValueChanged<bool>? onFocusChanged;
  final void Function(String value, bool edited, bool touched)? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppStandardQuoteInputCell({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.type,
    required this.enabled,
    required this.hintText,
    this.wasEdited = false,
    this.wasTouched = false,
    this.wasPrefilled = false,
    this.onMoveNext,
    this.onMovePrevious,
    this.onFocusChanged,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AppStandardQuoteInputCell> createState() =>
      _AppStandardQuoteInputCellState();
}

class _AppStandardQuoteInputCellState extends State<AppStandardQuoteInputCell> {
  bool _edited = false;
  bool _touched = false;

  bool get _isMoney => widget.type == AppStandardQuoteInputType.money;

  bool get _isEdited => _edited || widget.wasEdited;
  bool get _isTouched => _touched || widget.wasTouched;

  static const Color _activeBorder = Color(0xFFBF9000);
  static const Color _editedBorder = Color(0xFF70AD47);
  static const Color _touchedBorder = Color(0xFFED7D31);
  static const Color _hoverBorder = Color(0xFF5B9BD5);
  static const Color _defaultBorder = Color(0xFFD9E2F3);

  @override
  void initState() {
    super.initState();

    _edited = widget.wasEdited;
    _touched = widget.wasTouched;

    widget.focusNode.addListener(_handleFocusChanged);
    widget.focusNode.onKeyEvent = _handleKeyEvent;
  }

  @override
  void didUpdateWidget(covariant AppStandardQuoteInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    _edited = widget.wasEdited || _edited;
    _touched = widget.wasTouched || _touched;

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      oldWidget.focusNode.onKeyEvent = null;

      widget.focusNode.addListener(_handleFocusChanged);
      widget.focusNode.onKeyEvent = _handleKeyEvent;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);

    if (widget.focusNode.onKeyEvent == _handleKeyEvent) {
      widget.focusNode.onKeyEvent = null;
    }

    super.dispose();
  }

  void _handleFocusChanged() {
    widget.onFocusChanged?.call(widget.focusNode.hasFocus);

    if (!widget.focusNode.hasFocus) {
      _normalizeOnFinish();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.focusNode.hasFocus) return;

      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onMoveNext?.call();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onMovePrevious?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String _normalizeMoney(String value) {
    final clean = value.replaceAll(',', '').trim();
    if (clean.isEmpty) return '';

    final parsed = num.tryParse(clean);
    if (parsed == null || parsed <= 0) return '';

    return parsed.toStringAsFixed(2);
  }

  String _normalizeQuantity(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (clean.isEmpty) return '';
    return clean;
  }

  void _normalizeOnFinish() {
    final normalized = _isMoney
        ? _normalizeMoney(widget.controller.text)
        : _normalizeQuantity(widget.controller.text);

    if (widget.controller.text != normalized) {
      widget.controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    widget.onSubmitted?.call(normalized);
  }

  void _emitChanged(String value) {
    final edited = value.trim().isNotEmpty;
    const touched = true;

    setState(() {
      _edited = edited;
      _touched = touched;
    });

    widget.onChanged?.call(value, edited, touched);
  }

  Color _borderColor(Set<WidgetState> states) {
    if (widget.focusNode.hasFocus) return _activeBorder;
    if (_isEdited) return _editedBorder;
    if (_isTouched) return _touchedBorder;
    if (states.contains(WidgetState.hovered)) return _hoverBorder;
    return _defaultBorder;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = !widget.enabled
        ? Colors.grey.shade600
        : _isEdited
        ? const Color(0xFF166534)
        : const Color(0xFF334155);

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      textAlign: TextAlign.center,
      keyboardType: _isMoney
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        _isMoney
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(
        fontSize: 12,
        height: 1,
        fontWeight: FontWeight.w900,
        color: textColor,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.transparent,
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 9,
        ),
        border: WidgetStateInputBorder.resolveWith(
              (states) => OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _borderColor(states),
              width: widget.focusNode.hasFocus ? 1.8 : 1.2,
            ),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isEdited
                ? _editedBorder
                : _isTouched
                ? _touchedBorder
                : _defaultBorder,
            width: _isEdited || _isTouched ? 1.4 : 1.1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: _activeBorder,
            width: 1.8,
          ),
        ),
      ),
      onTap: () {
        widget.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.controller.text.length,
        );
      },
      onChanged: _emitChanged,
      onSubmitted: (_) => _normalizeOnFinish(),
    );
  }
}
