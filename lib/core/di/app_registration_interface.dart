import 'package:get_it/get_it.dart';

abstract class RegistrationInterface {
  void registerBlocs(GetIt sl);
  void registerUseCases(GetIt sl);
  void registerRepositories(GetIt sl);
}
