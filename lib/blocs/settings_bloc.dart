import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SettingsEvent {}

class LoadSettingsEvent extends SettingsEvent {}

abstract class SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String settings;

  SettingsLoaded(this.settings);
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsLoading());

  @override
  Stream<SettingsState> mapEventToState(SettingsEvent event) async* {
    if (event is LoadSettingsEvent) {
      yield SettingsLoading();
      try {
        // Simulate a delay and fetch settings
        await Future.delayed(Duration(seconds: 2));
        yield SettingsLoaded('User settings loaded');
      } catch (e) {
        yield SettingsError('Failed to load settings');
      }
    }
  }
}
