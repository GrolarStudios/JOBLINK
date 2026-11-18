import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Acerca de la App"),
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ListView(
          children: [
            Text(
              'Finance Control',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versión 1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle(context, "Nuestra misión"),
            _sectionText(
              "Finance Control es una aplicación diseñada para ayudarte "
                  "a administrar tus finanzas personales de manera simple, "
                  "intuitiva y eficiente. Nuestra misión es brindarte herramientas "
                  "claras que te permitan tomar decisiones financieras inteligentes.",
            ),

            _sectionTitle(context, "¿Qué puedes hacer con la app?"),
            _sectionText(
              "• Registrar ingresos y gastos.\n"
                  "• Llevar control de presupuestos.\n"
                  "• Visualizar estadísticas financieras.\n"
                  "• Analizar hábitos de consumo.\n"
                  "• Mejorar tu educación financiera.",
            ),

            _sectionTitle(context, "Tecnología"),
            _sectionText(
              "La aplicación está desarrollada con Flutter, lo que garantiza "
                  "un rendimiento rápido, una experiencia fluida y compatibilidad "
                  "multiplataforma.",
            ),

            _sectionTitle(context, "Compromiso"),
            _sectionText(
              "Estamos comprometidos con la transparencia, la seguridad "
                  "de tus datos y la mejora continua del producto para ofrecerte "
                  "una experiencia confiable y profesional.",
            ),

            const SizedBox(height: 30),

            Divider(color: scheme.outlineVariant),

            const SizedBox(height: 12),

            Text(
              '© 2026 Grolar Studios\nTodos los derechos reservados.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}