import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../../../../../core/utils/text/app_global_variables.dart';
import '../widgets/profile_info_page.dart';
import '../widgets/privacy_policy_page.dart';
import '../widgets/terms_conditions_page.dart';
import '../widgets/about_app_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final box = Hive.box('userBox');
      await box.clear();

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Globals.initialize(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final box = Hive.box('userBox');

    final nombre = box.get("nombre", defaultValue: "");
    final apellido = box.get("apellido", defaultValue: "");
    final correo = box.get("correo", defaultValue: "");

    final fullName = "$nombre $apellido".trim().isEmpty
        ? "Usuario"
        : "$nombre $apellido".trim();

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          Globals.profile,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            final bool isMobile = screenWidth < 700;
            final bool isTablet = screenWidth >= 700 && screenWidth < 1100;
            final bool isDesktop = screenWidth >= 1100;

            final double maxContentWidth = isDesktop
                ? 900
                : isTablet
                ? 700
                : 500;

            final double horizontalPadding = isMobile ? 16 : 24;
            final double avatarRadius = isMobile ? 44 : 56;
            final double sectionSpacing = isMobile ? 18 : 24;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(
                        fullName: fullName,
                        correo: correo,
                        avatarRadius: avatarRadius,
                      ),

                      SizedBox(height: sectionSpacing),

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SectionCard(
                                title: "Cuenta",
                                icon: Icons.person_outline,
                                child: Column(
                                  children: [
                                    _ProfileOptionTile(
                                      icon: Icons.badge_outlined,
                                      iconColor: colorScheme.primary,
                                      title: Globals.personalInfo,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const ProfileInfoPage(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _SectionCard(
                                title: "Información legal",
                                icon: Icons.gavel_outlined,
                                child: Column(
                                  children: [
                                    _ProfileOptionTile(
                                      icon: Icons.privacy_tip_outlined,
                                      iconColor: colorScheme.primary,
                                      title: Globals.privacyPolicy,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const PrivacyPolicyPage(),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 0),
                                    _ProfileOptionTile(
                                      icon: Icons.description_outlined,
                                      iconColor: colorScheme.primary,
                                      title: Globals.termsConditions,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const TermsConditionsPage(),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 0),
                                    _ProfileOptionTile(
                                      icon: Icons.info_outline,
                                      iconColor: colorScheme.primary,
                                      title: Globals.aboutApp,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const AboutAppPage(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _SectionCard(
                          title: "Cuenta",
                          icon: Icons.person_outline,
                          child: Column(
                            children: [
                              _ProfileOptionTile(
                                icon: Icons.badge_outlined,
                                iconColor: colorScheme.primary,
                                title: Globals.personalInfo,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileInfoPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionSpacing),
                        _SectionCard(
                          title: "Información legal",
                          icon: Icons.gavel_outlined,
                          child: Column(
                            children: [
                              _ProfileOptionTile(
                                icon: Icons.privacy_tip_outlined,
                                iconColor: colorScheme.primary,
                                title: Globals.privacyPolicy,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const PrivacyPolicyPage(),
                                  ),
                                ),
                              ),
                              const Divider(height: 0),
                              _ProfileOptionTile(
                                icon: Icons.description_outlined,
                                iconColor: colorScheme.primary,
                                title: Globals.termsConditions,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const TermsConditionsPage(),
                                  ),
                                ),
                              ),
                              const Divider(height: 0),
                              _ProfileOptionTile(
                                icon: Icons.info_outline,
                                iconColor: colorScheme.primary,
                                title: Globals.aboutApp,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AboutAppPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: sectionSpacing + 8),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _logout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 16 : 18,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(
                            Globals.logout,
                            style: TextStyle(
                              fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String correo;
  final double avatarRadius;

  const _ProfileHeader({
    required this.fullName,
    required this.correo,
    required this.avatarRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.18),
                  colorScheme.secondary.withOpacity(0.10),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: colorScheme.surface,
              backgroundImage: const AssetImage("assets/img/user_image.png"),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            correo.isEmpty ? "Sin correo registrado" : correo,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.verified_user_outlined,
                label: "Cuenta activa",
              ),
              _InfoChip(
                icon: Icons.devices_outlined,
                label: "Perfil seguro",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            title: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "Ver detalle",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}