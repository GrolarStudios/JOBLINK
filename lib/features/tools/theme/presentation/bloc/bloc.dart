import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../../../core/helpers/app_theme_preferences.dart';

class ThemeBloc extends Bloc<BaseEvent, BaseState> {
  ThemeBloc() : super(ThemeInitialState()) {
    on<InitializeThemeEvent>((event, emit) async {
      bool isDarkMode = await ThemePreferences.getThemePreference();
      emit(ThemeChangedState(isDarkMode: isDarkMode));
    });

    on<ToggleThemeEvent>((event, emit) async {
      await ThemePreferences.saveThemePreference(event.isDarkMode);
      emit(ThemeChangedState(isDarkMode: event.isDarkMode));
    });
  }
}
