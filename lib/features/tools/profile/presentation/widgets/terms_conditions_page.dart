import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Términos y Condiciones"),
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
              'Términos y Condiciones de Uso',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle(context, "1. Aceptación de los términos"),
            _sectionText(
              "Al acceder y utilizar esta aplicación, usted acepta cumplir "
                  "con los presentes Términos y Condiciones, así como con todas "
                  "las leyes y regulaciones aplicables. Si no está de acuerdo "
                  "con alguno de estos términos, le recomendamos no utilizar la aplicación.",
            ),

            _sectionTitle(context, "2. Uso de la aplicación"),
            _sectionText(
              "El usuario se compromete a utilizar la aplicación de manera "
                  "responsable y únicamente para los fines permitidos. "
                  "Queda prohibido el uso indebido, la manipulación no autorizada "
                  "del sistema o cualquier actividad que pueda afectar su funcionamiento.",
            ),

            _sectionTitle(context, "3. Protección de datos"),
            _sectionText(
              "Nos comprometemos a proteger la información personal "
                  "proporcionada por los usuarios. Los datos recopilados serán "
                  "utilizados exclusivamente para mejorar la experiencia dentro "
                  "de la aplicación y no serán compartidos con terceros sin consentimiento.",
            ),

            _sectionTitle(context, "4. Propiedad intelectual"),
            _sectionText(
              "Todo el contenido presente en la aplicación, incluyendo "
                  "textos, imágenes, logotipos, diseño y código fuente, "
                  "es propiedad de la empresa y está protegido por las leyes "
                  "de propiedad intelectual. Queda prohibida su reproducción "
                  "sin autorización previa.",
            ),

            _sectionTitle(context, "5. Limitación de responsabilidad"),
            _sectionText(
              "La empresa no será responsable por daños directos o "
                  "indirectos derivados del uso o la imposibilidad de uso "
                  "de la aplicación. El uso del servicio es bajo su propio riesgo.",
            ),

            _sectionTitle(context, "6. Modificaciones"),
            _sectionText(
              "Nos reservamos el derecho de modificar estos términos "
                  "en cualquier momento. Las actualizaciones serán publicadas "
                  "en esta misma sección y entrarán en vigor inmediatamente.",
            ),

            _sectionTitle(context, "7. Contacto"),
            _sectionText(
              "Si tiene alguna duda respecto a estos Términos y Condiciones, "
                  "puede comunicarse con nuestro equipo de soporte a través "
                  "de los canales oficiales proporcionados dentro de la aplicación.",
            ),

            const SizedBox(height: 30),

            Text(
              "Última actualización: Enero 2026",
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