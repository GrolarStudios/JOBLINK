import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/text/app_global_variables.dart';
import '../../../../tools/theme/presentation/bloc/bloc.dart';
import '../../../../tools/theme/presentation/bloc/state.dart';
import '../../../../tools/theme/presentation/bloc/event.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    Globals.initialize(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    context.read<ThemeBloc>().add(InitializeThemeEvent());

    return Scaffold(
      backgroundColor: colorScheme.background,

      appBar: AppBar(
        title: Text(
          Globals.theme,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      body: Center(
        child: BlocBuilder<ThemeBloc, BaseState>(
          builder: (context, state) {
            bool isDarkMode =
            state is ThemeChangedState ? state.isDarkMode : false;

            return Card(
              color: colorScheme.surface,
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Text(
                  Globals.modBlack,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  isDarkMode
                      ? "Modo oscuro activado"
                      : "Modo claro activado",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withOpacity(0.6),
                  ),
                ),
                value: isDarkMode,
                activeColor: colorScheme.primary,
                onChanged: (bool value) {
                  context.read<ThemeBloc>().add(
                    ToggleThemeEvent(value),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
