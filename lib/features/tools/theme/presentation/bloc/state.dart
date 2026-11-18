abstract class BaseState {}

class ThemeInitialState extends BaseState {}

class ThemeChangedState extends BaseState {
  final bool isDarkMode;

  ThemeChangedState({required this.isDarkMode});
}