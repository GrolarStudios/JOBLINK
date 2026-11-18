import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppPedInputCell extends StatefulWidget {
  final FocusNode focusNode;
  final String initialValue;
  final String originalValue;
  final bool wasPrefilled;
  final bool wasEdited;
  final bool wasTouched;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final void Function(String value, bool edited, bool touched)? onChanged;
  final Future<void> Function(String value)? onSubmitted;

  const AppPedInputCell({
    super.key,
    required this.focusNode,
    required this.initialValue,
    required this.originalValue,
    this.wasPrefilled = false,
    this.wasEdited = false,
    this.wasTouched = false,
    this.onMoveUp,
    this.onMoveDown,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AppPedInputCell> createState() => _AppPedInputCellState();
}

class _AppPedInputCellState extends State<AppPedInputCell> {
  late final TextEditingController _controller;

  bool _edited = false;
  bool _touched = false;

  static const Color _excelActiveBorder = Color(0xFFBF9000);
  static const Color _excelEditedBorder = Color(0xFF70AD47);
  static const Color _excelTouchedBorder = Color(0xFFED7D31);
  static const Color _excelHoverBorder = Color(0xFF5B9BD5);
  static const Color _excelDefaultBorder = Color(0xFFD9E2F3);

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
    _edited = widget.wasEdited;
    _touched = widget.wasTouched;

    widget.focusNode.addListener(_handleFocusChanged);
    widget.focusNode.onKeyEvent = _handleKeyEvent;
  }

  @override
  void didUpdateWidget(covariant AppPedInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      oldWidget.focusNode.onKeyEvent = null;

      widget.focusNode.addListener(_handleFocusChanged);
      widget.focusNode.onKeyEvent = _handleKeyEvent;
    }

    _edited = widget.wasEdited || _edited;
    _touched = widget.wasTouched || _touched;

    if (!widget.focusNode.hasFocus && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);

    if (widget.focusNode.onKeyEvent == _handleKeyEvent) {
      widget.focusNode.onKeyEvent = null;
    }

    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;

    setState(() {});

    if (!widget.focusNode.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.focusNode.hasFocus) return;
      if (_controller.text.isEmpty) return;

      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onMoveUp?.call();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onMoveDown?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool get _isEdited {
    final original = widget.originalValue.trim();
    final current = _controller.text.trim();

    final originalNumber = int.tryParse(original) ?? 0;
    final currentNumber = int.tryParse(current) ?? 0;

    return _edited ||
        widget.wasEdited ||
        (currentNumber > 0 && currentNumber != originalNumber);
  }

  bool get _isTouched {
    return _touched || widget.wasTouched;
  }

  Color _borderColor(Set<MaterialState> states) {
    if (widget.focusNode.hasFocus) {
      return _excelActiveBorder;
    }

    if (_isEdited) {
      return _excelEditedBorder;
    }

    if (_isTouched) {
      return _excelTouchedBorder;
    }

    if (states.contains(MaterialState.hovered)) {
      return _excelHoverBorder;
    }

    return _excelDefaultBorder;
  }

  void _emitChanged(String value) {
    final original = widget.originalValue.trim();
    final current = value.trim();

    final originalNumber = int.tryParse(original) ?? 0;
    final currentNumber = int.tryParse(current) ?? 0;

    final edited = currentNumber > 0 && currentNumber != originalNumber;
    const touched = true;

    setState(() {
      _edited = edited;
      _touched = touched;
    });

    widget.onChanged?.call(value, edited, touched);
  }

  Future<void> _submit() async {
    await widget.onSubmitted?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isEdited
        ? const Color(0xFF166534)
        : const Color(0xFF334155);

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(
        fontSize: 12,
        height: 1,
        fontWeight: FontWeight.w900,
        color: textColor,
      ),
      decoration: InputDecoration(
        isDense: true,

        // IMPORTANTE:
        // El fondo queda transparente para que se vea el color de toda la fila.
        filled: true,
        fillColor: Colors.transparent,

        hintText: '0',
        hintStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 9,
        ),
        border: MaterialStateOutlineInputBorder.resolveWith(
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
                ? _excelEditedBorder
                : _isTouched
                ? _excelTouchedBorder
                : _excelDefaultBorder,
            width: _isEdited || _isTouched ? 1.4 : 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: _excelActiveBorder,
            width: 1.8,
          ),
        ),
      ),
      onTap: () {
        if (_controller.text.isEmpty) return;

        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      },
      onChanged: _emitChanged,
      onSubmitted: (_) => _submit(),
    );
  }
}
