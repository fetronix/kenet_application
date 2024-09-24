import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class ApplicationsEvent {}

class LoadApplicationsEvent extends ApplicationsEvent {}

// States
abstract class ApplicationsState {}

class ApplicationsLoading extends ApplicationsState {}

class ApplicationsLoaded extends ApplicationsState {
  final List<String> applications;

  ApplicationsLoaded(this.applications);
}

class ApplicationsError extends ApplicationsState {}

// Bloc
class ApplicationsBloc extends Bloc<ApplicationsEvent, ApplicationsState> {
  ApplicationsBloc() : super(ApplicationsLoading());

  @override
  Stream<ApplicationsState> mapEventToState(ApplicationsEvent event) async* {
    if (event is LoadApplicationsEvent) {
      // Simulate loading data
      await Future.delayed(Duration(seconds: 2));
      yield ApplicationsLoaded(['Application 1', 'Application 2', 'Application 3']);
    }
  }
}
