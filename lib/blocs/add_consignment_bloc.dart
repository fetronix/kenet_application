import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class AddConsignmentEvent {}

class SubmitConsignmentEvent extends AddConsignmentEvent {
  final String slkId;
  final String supplier;
  final int quantity;

  SubmitConsignmentEvent({required this.slkId, required this.supplier, required this.quantity});
}

// States
abstract class AddConsignmentState {}

class AddConsignmentInitial extends AddConsignmentState {}

class AddConsignmentLoading extends AddConsignmentState {}

class AddConsignmentSuccess extends AddConsignmentState {}

class AddConsignmentError extends AddConsignmentState {}

// Bloc
class AddConsignmentBloc extends Bloc<AddConsignmentEvent, AddConsignmentState> {
  AddConsignmentBloc() : super(AddConsignmentInitial());

  @override
  Stream<AddConsignmentState> mapEventToState(AddConsignmentEvent event) async* {
    if (event is SubmitConsignmentEvent) {
      yield AddConsignmentLoading();

      // Simulate a network call
      await Future.delayed(Duration(seconds: 2));

      // Here you would typically make an API call to save the consignment
      // If successful:
      yield AddConsignmentSuccess();
      // If there's an error, yield AddConsignmentError();
    }
  }
}
