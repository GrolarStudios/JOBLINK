import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/l10n/localizations.dart';
import 'core/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/app_providers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/utils/text/app_global_variables.dart';
import 'features/tools/theme/presentation/bloc/bloc.dart';
import 'features/tools/theme/presentation/bloc/event.dart';
import 'features/tools/theme/presentation/bloc/state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bootstrap/app_initializer.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  bool _themeLoaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final isDarkMode = await AppInitializer.loadInitialTheme();

      if (!mounted) return;

      setState(() {
        _isDarkMode = isDarkMode;
        _themeLoaded = true;
      });

      AppInitializer.initializeDeferred();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDarkMode = false;
        _themeLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(
            create: (_) => ThemeBloc()..add(ToggleThemeEvent(_isDarkMode)),
          ),
        ],
        child: BlocBuilder<ThemeBloc, BaseState>(
          builder: (context, state) {
            final bool isDark =
            state is ThemeChangedState ? state.isDarkMode : _isDarkMode;

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: Globals.titleMain,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('es'),
              ],
              onGenerateRoute: AppRoutes.generateRoute,
              initialRoute: RouteNames.empleo,
              builder: (context, child) {
                if (!_themeLoaded) {
                  return const Material(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return child ?? const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}
