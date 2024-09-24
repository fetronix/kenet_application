import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dispatch_cart_item.dart'; // Make sure to import your DispatchCartItem model

// Checkout Events
abstract class CheckoutEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class InitiateCheckoutEvent extends CheckoutEvent {
  final List<DispatchCartItem> items;

  InitiateCheckoutEvent(this.items);
}

class ConfirmCheckoutEvent extends CheckoutEvent {}

// Checkout States
abstract class CheckoutState extends Equatable {
  @override
  List<Object> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final String message;

  CheckoutSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class CheckoutError extends CheckoutState {
  final String error;

  CheckoutError(this.error);

  @override
  List<Object> get props => [error];
}

// Checkout BLoC
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc() : super(CheckoutInitial());

  @override
  Stream<CheckoutState> mapEventToState(CheckoutEvent event) async* {
    if (event is InitiateCheckoutEvent) {
      yield CheckoutLoading();
      try {
        // Simulate a checkout process (e.g., API call)
        await Future.delayed(Duration(seconds: 2)); // Simulate network delay

        // Assuming the checkout process was successful
        yield CheckoutSuccess('Checkout successful!'); // Change this to an appropriate success message
      } catch (e) {
        yield CheckoutError('Checkout failed: ${e.toString()}');
      }
    } else if (event is ConfirmCheckoutEvent) {
      // Handle any additional confirmation actions if needed
    }
  }
}
