import 'package:equatable/equatable.dart';

abstract class BaseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ToggleThemeEvent extends BaseEvent {
  final bool isDarkMode;

  ToggleThemeEvent(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}

class InitializeThemeEvent extends BaseEvent {}
