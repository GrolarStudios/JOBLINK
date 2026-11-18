import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aviso de Privacidad"),
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
              'Aviso de Privacidad',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle(context, "1. Identidad y domicilio del responsable"),
            _sectionText(
              "La empresa responsable del tratamiento de sus datos personales "
                  "es la titular de esta aplicación. Nos comprometemos a proteger "
                  "su información conforme a la Ley Federal de Protección de Datos "
                  "Personales en Posesión de los Particulares (LFPDPPP) y demás "
                  "normatividad aplicable en México.",
            ),

            _sectionTitle(context, "2. Datos personales que recopilamos"),
            _sectionText(
              "Podemos recopilar datos personales como nombre, correo electrónico, "
                  "número telefónico, información de registro y datos técnicos del dispositivo. "
                  "La información se obtiene cuando el usuario la proporciona de forma "
                  "directa o al utilizar la aplicación.",
            ),

            _sectionTitle(context, "3. Finalidad del tratamiento de datos"),
            _sectionText(
              "Los datos personales serán utilizados para: "
                  "• Proveer y mejorar nuestros servicios.\n"
                  "• Contactar al usuario para soporte o información relevante.\n"
                  "• Cumplir obligaciones legales.\n"
                  "• Analizar estadísticas internas para mejorar la experiencia del usuario.",
            ),

            _sectionTitle(context, "4. Protección y seguridad"),
            _sectionText(
              "Implementamos medidas de seguridad administrativas, técnicas y físicas "
                  "para proteger sus datos personales contra daño, pérdida, alteración "
                  "o acceso no autorizado.",
            ),

            _sectionTitle(context, "5. Derechos ARCO"),
            _sectionText(
              "Usted tiene derecho a Acceder, Rectificar, Cancelar u Oponerse "
                  "al tratamiento de sus datos personales (Derechos ARCO). "
                  "Para ejercer estos derechos, puede comunicarse a través "
                  "de los medios de contacto proporcionados en la aplicación.",
            ),

            _sectionTitle(context, "6. Transferencia de datos"),
            _sectionText(
              "Sus datos personales no serán compartidos con terceros sin su "
                  "consentimiento, salvo en los casos previstos por la ley.",
            ),

            _sectionTitle(context, "7. Cambios al aviso de privacidad"),
            _sectionText(
              "Nos reservamos el derecho de modificar este Aviso de Privacidad "
                  "en cualquier momento. Las actualizaciones serán publicadas en "
                  "esta sección dentro de la aplicación.",
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