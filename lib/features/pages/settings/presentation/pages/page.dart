import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/text/app_global_variables.dart';
import '../../../../tools/profile/presentation/pages/page.dart';
import '../../../../tools/notification/presentation/pages/page.dart';
import '../../../../tools/theme/presentation/bloc/bloc.dart';
import '../../../../tools/theme/presentation/bloc/state.dart';
import '../../../../tools/theme/presentation/bloc/event.dart';

class SettingOption {
  final String name;
  final IconData icon;
  final Widget page;

  SettingOption({
    required this.name,
    required this.icon,
    required this.page,
  });
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ThemeBloc>().add(InitializeThemeEvent());
      }
    });
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    return 2;
  }

  double _getHorizontalPadding(double width) {
    if (width >= 1200) return 40;
    if (width >= 900) return 32;
    if (width >= 600) return 24;
    return 16;
  }

  double _getIconSize(double width) {
    if (width >= 1200) return 28;
    if (width >= 900) return 26;
    if (width >= 600) return 24;
    return 22;
  }

  @override
  Widget build(BuildContext context) {
    Globals.initialize(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final settingsOptions = [
      SettingOption(
        name: Globals.profile,
        icon: Icons.person,
        page: const ProfilePage(),
      ),
      SettingOption(
        name: Globals.notifications,
        icon: Icons.notifications,
        page: const NotificationsPage(),
      ),
    ];

    return BlocBuilder<ThemeBloc, BaseState>(
      builder: (context, state) {
        final bool isDarkMode =
        state is ThemeChangedState ? state.isDarkMode : false;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = _getCrossAxisCount(width);
            final horizontalPadding = _getHorizontalPadding(width);
            final iconSize = _getIconSize(width);

            final bool isLargeScreen = width >= 900;
            final double maxContentWidth = isLargeScreen ? 1100 : double.infinity;

            return Scaffold(
              backgroundColor: colorScheme.background,
              body: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          color: colorScheme.surface,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width >= 600 ? 24 : 16,
                              vertical: width >= 600 ? 20 : 14,
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                Globals.modBlack,
                                style: (width >= 600
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.titleMedium)
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                isDarkMode
                                    ? "Modo oscuro activado"
                                    : "Modo claro activado",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              value: isDarkMode,
                              activeColor: colorScheme.primary,
                              onChanged: (bool value) {
                                context
                                    .read<ThemeBloc>()
                                    .add(ToggleThemeEvent(value));
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: settingsOptions.length,
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.2,
                          ),
                          itemBuilder: (context, index) {
                            final option = settingsOptions[index];

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => option.page,
                                  ),
                                );
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                                color: colorScheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        option.icon,
                                        size: iconSize,
                                        color: theme.iconTheme.color,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          option.name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
