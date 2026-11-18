import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/komanda_theme.dart';
import '../../domain/entities/komanda_ticket_config.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../widgets/komanda_widgets.dart';

class KomandaTicketSettingsPage extends StatefulWidget {
  const KomandaTicketSettingsPage({super.key});

  @override
  State<KomandaTicketSettingsPage> createState() => _State();
}

class _State extends State<KomandaTicketSettingsPage> {
  late TextEditingController name;
  late TextEditingController address;
  late TextEditingController phone;
  late TextEditingController footer;
  late TextEditingController plateLabel;
  late KomandaTicketConfig config;

  @override
  void initState() {
    super.initState();
    config = context.read<KomandaBloc>().state.ticketConfig;
    name = TextEditingController(text: config.businessName);
    address = TextEditingController(text: config.address);
    phone = TextEditingController(text: config.phone);
    footer = TextEditingController(text: config.footer);
    plateLabel = TextEditingController(text: config.plateLabel);
  }

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    phone.dispose();
    footer.dispose();
    plateLabel.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    setState(() {
      config = config.copyWith(
        logoBase64: base64Encode(bytes),
      );
    });
  }

  Widget _buildTicketSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double safeFontScale =
        config.fontScale.clamp(0.80, 1.50).toDouble();

    return KomandaPhoneFrame(
      child: Column(
        children: [
          KomandaHeader(
            title: 'Configurar ticket',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: config.logoBase64.isEmpty
                            ? const Icon(
                                Icons.storefront_outlined,
                                size: 42,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(config.logoBase64),
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickLogo,
                            icon: const Icon(Icons.upload),
                            label: const Text('Subir logo'),
                          ),
                          if (config.logoBase64.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  config = config.copyWith(
                                    logoBase64: '',
                                  );
                                });
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Quitar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: plateLabel,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Nombre del grupo en pedidos y ticket', hintText: 'Ej. Servicio, Plato, Orden', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del negocio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: footer,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje final',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KomandaTheme.purple.withOpacity(.055),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: KomandaTheme.purple.withOpacity(.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipografía del ticket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tamaño ${(safeFontScale * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Slider(
                        value: safeFontScale,
                        min: 0.80,
                        max: 1.50,
                        divisions: 14,
                        label: '${(safeFontScale * 100).round()}%',
                        onChanged: (double value) {
                          setState(() {
                            config = config.copyWith(
                              fontScale: value,
                            );
                          });
                        },
                      ),
                      DropdownButtonFormField<int>(
                        value: config.fontWeight >= 700 ? 700 : 400,
                        decoration: const InputDecoration(
                          labelText: 'Grosor de letra',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<int>(
                            value: 400,
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem<int>(
                            value: 700,
                            child: Text('Negrita'),
                          ),
                        ],
                        onChanged: (int? value) {
                          setState(() {
                            config = config.copyWith(
                              fontWeight: value ?? 400,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vista: Carnitas Cornejo · Producto x 2 · \$150.00',
                        style: TextStyle(
                          fontSize: 13 * safeFontScale,
                          fontWeight: config.fontWeight >= 700
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildTicketSwitch(
                  title: 'Mostrar folio',
                  value: config.showFolio,
                  onChanged: (bool value) {
                    setState(() {
                      config = config.copyWith(
                        showFolio: value,
                      );
                    });
                  },
                ),
                _buildTicketSwitch(
                  title: 'Mostrar mesa/tipo',
                  value: config.showTable,
                  onChanged: (bool value) {
                    setState(() {
                      config = config.copyWith(
                        showTable: value,
                      );
                    });
                  },
                ),
                _buildTicketSwitch(
                  title: 'Mostrar fecha',
                  value: config.showDate,
                  onChanged: (bool value) {
                    setState(() {
                      config = config.copyWith(
                        showDate: value,
                      );
                    });
                  },
                ),
                _buildTicketSwitch(
                  title: 'Mostrar especificaciones',
                  value: config.showItemSpecifications,
                  onChanged: (bool value) {
                    setState(() {
                      config = config.copyWith(
                        showItemSpecifications: value,
                      );
                    });
                  },
                ),
                _buildTicketSwitch(
                  title: 'Mostrar propina',
                  value: config.showTip,
                  onChanged: (bool value) {
                    setState(() {
                      config = config.copyWith(
                        showTip: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    final updated = config.copyWith(
                      businessName: name.text.trim(),
                      address: address.text.trim(),
                      phone: phone.text.trim(),
                      footer: footer.text.trim(),
                      plateLabel: plateLabel.text.trim().isEmpty ? 'Plato' : plateLabel.text.trim(),
                    );

                    context.read<KomandaBloc>().add(
                          KomandaTicketConfigSaved(updated),
                        );

                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar configuración'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
