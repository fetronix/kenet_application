import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class WalkthroughEvent {}

class WalkthroughComplete extends WalkthroughEvent {}

class CheckWalkthroughStatus extends WalkthroughEvent {}

// State
abstract class WalkthroughState {}

class WalkthroughInitial extends WalkthroughState {}

class WalkthroughSeen extends WalkthroughState {}

class WalkthroughUnseen extends WalkthroughState {}

// BLoC
class WalkthroughBloc extends Bloc<WalkthroughEvent, WalkthroughState> {
  WalkthroughBloc() : super(WalkthroughInitial()) {
    on<CheckWalkthroughStatus>((event, emit) {
      // Simulate checking from local storage if the walkthrough has been seen
      // For now, assume the user has not seen the walkthrough (for simplicity).
      bool hasSeenWalkthrough = false; 
      
      if (hasSeenWalkthrough) {
        emit(WalkthroughSeen());
      } else {
        emit(WalkthroughUnseen());
      }
    });

    on<WalkthroughComplete>((event, emit) {
      // Simulate saving the status of walkthrough being completed
      emit(WalkthroughSeen());
    });
  }
}
