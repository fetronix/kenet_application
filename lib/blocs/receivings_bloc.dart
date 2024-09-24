import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class ReceivingsEvent {}

class LoadReceivingsEvent extends ReceivingsEvent {}

// States
abstract class ReceivingsState {}

class ReceivingsLoading extends ReceivingsState {}

class ReceivingsLoaded extends ReceivingsState {
  final List<String> receivings;

  ReceivingsLoaded(this.receivings);
}

class ReceivingsError extends ReceivingsState {}

// Bloc
class ReceivingsBloc extends Bloc<ReceivingsEvent, ReceivingsState> {
  ReceivingsBloc() : super(ReceivingsLoading());

  @override
  Stream<ReceivingsState> mapEventToState(ReceivingsEvent event) async* {
    if (event is LoadReceivingsEvent) {
      // Simulate loading data
      await Future.delayed(Duration(seconds: 2));
      yield ReceivingsLoaded(['Receiving 1', 'Receiving 2', 'Receiving 3']);
    }
  }
}
