import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../complements_pages/app_standard_table_widgets.dart';

class AppAuctionNumberFormatters {
  const AppAuctionNumberFormatters._();

  static num toNum(dynamic value) {
    if (value == null) return 0;

    final clean = value
        .toString()
        .replaceAll(r'$', '')
        .replaceAll(',', '')
        .trim();

    return num.tryParse(clean) ?? 0;
  }

  static String formatNumberWithThousands(num value) {
    final fixed = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final parts = fixed.split('.');
    final integer = parts[0];
    final decimal = parts.length > 1 ? '.${parts[1]}' : '';

    final buffer = StringBuffer();

    for (int i = 0; i < integer.length; i++) {
      final positionFromEnd = integer.length - i;
      buffer.write(integer[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${buffer.toString()}$decimal';
  }

  static String formatMoneyValue(num value) {
    return '\$${formatNumberWithThousands(value)}';
  }

  static num costoSubastaAnterior(List<Map<String, dynamic>> rows) {
    num total = 0;

    for (final row in rows) {
      final ultimoCosto = toNum(
        row['ultCosto'] ??
            row['ultimoCosto'] ??
            row['ultimo_costo'] ??
            row['costoUltimo'],
      );

      final ultimaCompra = toNum(
        row['cantCompra'] ??
            row['ultimaCompra'] ??
            row['ultCompra'] ??
            row['cantidadUltimaCompra'],
      );

      if (ultimoCosto > 0 && ultimaCompra > 0) {
        total += ultimoCosto * ultimaCompra;
      }
    }

    return total;
  }
}

class AppAuctionDateHelpers {
  const AppAuctionDateHelpers._();

  static String formatShortDateTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty ||
        raw == '0000-00-00' ||
        raw == '0000-00-00 00:00:00' ||
        raw == '0000-00-00T00:00:00') {
      return 'Sin fecha';
    }

    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    final date = DateTime.tryParse(normalized);

    if (date == null) return raw;

    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = (date.year % 100).toString().padLeft(2, '0');

    final hasTime = raw.contains(':') &&
        !(date.hour == 0 && date.minute == 0 && date.second == 0);

    if (!hasTime) return '$day $month $year';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year $hour:$minute';
  }
}

class AppAuctionBulkQuantityBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onApply;

  const AppAuctionBulkQuantityBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppStandardEmojiButton(
          emoji: '✅',
          tooltip: 'Aplicar cantidad',
          onPressed: onApply,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 118,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            onSubmitted: (_) => onApply(),
            decoration: InputDecoration(
              hintText: 'Cant.',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF7C3AED),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppAuctionLetterFilters extends StatelessWidget {
  final List<String> letters;
  final String startLetter;
  final String endLetter;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;

  const AppAuctionLetterFilters({
    super.key,
    required this.letters,
    required this.startLetter,
    required this.endLetter,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeLetters = letters.isEmpty ? ['A'] : letters;
    final startValue = safeLetters.contains(startLetter) ? startLetter : safeLetters.first;
    final endValue = safeLetters.contains(endLetter) ? endLetter : safeLetters.last;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LetterDropdown(
          letters: safeLetters,
          value: startValue,
          tooltip: 'Desde',
          emoji: '🔠',
          onChanged: onStartChanged,
        ),
        const SizedBox(width: 8),
        _LetterDropdown(
          letters: safeLetters,
          value: endValue,
          tooltip: 'Hasta',
          emoji: '🔡',
          onChanged: onEndChanged,
        ),
      ],
    );
  }
}

class _LetterDropdown extends StatefulWidget {
  final List<String> letters;
  final String value;
  final String tooltip;
  final String emoji;
  final ValueChanged<String> onChanged;

  const _LetterDropdown({
    required this.letters,
    required this.value,
    required this.tooltip,
    required this.emoji,
    required this.onChanged,
  });

  @override
  State<_LetterDropdown> createState() => _LetterDropdownState();
}

class _LetterDropdownState extends State<_LetterDropdown> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHovered ? const Color(0xFF111827) : const Color(0xFFE2E8F0),
              width: isHovered ? 1.4 : 1,
            ),
            boxShadow: isHovered
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 21)),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.value,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: widget.letters.map((letter) {
                    return DropdownMenuItem<String>(
                      value: letter,
                      child: Text(
                        letter,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue == null) return;
                    widget.onChanged(newValue);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppAuctionSummaryCards extends StatelessWidget {
  final String subasta;
  final int productos;
  final num costoAnterior;

  const AppAuctionSummaryCards({
    super.key,
    required this.subasta,
    required this.productos,
    required this.costoAnterior,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppStandardInfoCard(title: 'Productos', value: AppAuctionNumberFormatters.formatNumberWithThousands(productos)),
        AppStandardInfoCard(title: 'Subasta', value: subasta),
        AppStandardInfoCard(title: 'Costo anterior', value: AppAuctionNumberFormatters.formatMoneyValue(costoAnterior)),
      ],
    );
  }
}

class AppAuctionHighlightCell extends StatelessWidget {
  final bool active;
  final Widget child;

  const AppAuctionHighlightCell({
    super.key,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFF3CD) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
