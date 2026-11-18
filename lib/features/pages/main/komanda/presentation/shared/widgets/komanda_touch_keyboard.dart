import 'package:flutter/material.dart';

/// Teclado opcional para terminales táctiles. No sustituye al teclado físico.
class KomandaTouchKeyboard {
  static Widget button(BuildContext context, TextEditingController controller,
      {bool numeric = false, bool uppercase = false, ValueChanged<String>? onChanged}) => IconButton(
    tooltip: 'Abrir teclado táctil',
    icon: const Icon(Icons.keyboard_alt_outlined),
    onPressed: () => show(context, controller, numeric: numeric, uppercase: uppercase, onChanged: onChanged),
  );

  static Future<void> show(BuildContext context, TextEditingController controller,
      {bool numeric = false, bool uppercase = false, ValueChanged<String>? onChanged}) async {
    // Al abrir el teclado, reemplazar el importe inicial con el primer dígito.
    if (numeric) {
      controller.selection = TextSelection(
        baseOffset: 0, extentOffset: controller.text.length,
      );
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) {
        void write(String key) {
          final value = controller.value;
          final start = value.selection.start < 0 ? value.text.length : value.selection.start;
          final end = value.selection.end < 0 ? value.text.length : value.selection.end;
          if (key == 'BORRAR') {
            if (start == end && start == 0) return;
            final from = start == end ? start - 1 : start;
            controller.value = TextEditingValue(
              text: value.text.replaceRange(from, end, ''),
              selection: TextSelection.collapsed(offset: from),
            );
          } else {
            final inserted = uppercase ? key.toUpperCase() : key;
            controller.value = TextEditingValue(
              text: value.text.replaceRange(start, end, inserted),
              selection: TextSelection.collapsed(offset: start + inserted.length),
            );
          }
          onChanged?.call(controller.text);
          refresh(() {});
        }
        final rows = numeric
            ? <List<String>>[['7','8','9'],['4','5','6'],['1','2','3'],['.','0','BORRAR']]
            : <List<String>>[
                'QWERTYUIOP'.split(''),
                'ASDFGHJKLÑ'.split(''),
                'ZXCVBNM'.split(''),
                ['ESPACIO', '.', ',', 'BORRAR'],
              ];
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Teclado táctil', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: Text(controller.text.isEmpty ? 'Escribe aquí…' : controller.text,
                    maxLines: 3, overflow: TextOverflow.ellipsis)),
                const SizedBox(height: 10),
                for (final row in rows)
                  Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
                    for (final key in row)
                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(height: 52, child: FilledButton.tonal(
                          onPressed: () => write(key == 'ESPACIO' ? ' ' : key),
                          style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                          child: key == 'BORRAR' ? const Icon(Icons.backspace_outlined) :
                            Text(key == 'ESPACIO' ? 'Espacio' : key, style: const TextStyle(fontSize: 17)),
                        )),
                      )),
                  ])),
                Align(alignment: Alignment.centerRight, child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Listo'),
                )),
              ]),
            ),
          ),
        );
      }),
    );
  }
}
