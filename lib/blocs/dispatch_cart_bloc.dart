import 'package:flutter_bloc/flutter_bloc.dart';
import 'dispatch_cart_item.dart';

// Events
abstract class DispatchCartEvent {}

// Event for loading the dispatch cart
class LoadDispatchCartEvent extends DispatchCartEvent {}

// Event for adding an item to the dispatch cart
class AddItemToDispatchCartEvent extends DispatchCartEvent {
  final DispatchCartItem item;

  AddItemToDispatchCartEvent(this.item);
}

// Event for adding a dispatch item (similar to AddItemToDispatchCartEvent, depending on how you distinguish them)
class AddDispatchItemEvent extends DispatchCartEvent {
  final DispatchCartItem item;

  AddDispatchItemEvent({required this.item});
}

// Event for clearing the dispatch cart
class ClearDispatchCartEvent extends DispatchCartEvent {}

// Event for removing an item from the dispatch cart
class RemoveItemFromDispatchCartEvent extends DispatchCartEvent {
  final DispatchCartItem item;

  RemoveItemFromDispatchCartEvent(this.item);
}

// States
abstract class DispatchCartState {}

// State indicating that the dispatch cart is currently loading
class DispatchCartLoading extends DispatchCartState {}

// State representing the loaded dispatch cart with a list of items
class DispatchCartLoaded extends DispatchCartState {
  final List<DispatchCartItem> items;

  DispatchCartLoaded(this.items);
}

// State indicating an error occurred while loading the dispatch cart or other operations
class DispatchCartError extends DispatchCartState {
  final String message;

  DispatchCartError(this.message);
}

// Bloc to manage dispatch cart state
class DispatchCartBloc extends Bloc<DispatchCartEvent, DispatchCartState> {
  // Internal list to hold dispatch cart items
  final List<DispatchCartItem> _dispatchCartItems = [];

  // Bloc constructor, initializing with DispatchCartLoading state
  DispatchCartBloc() : super(DispatchCartLoading()) {
    // Registering event handlers
    on<LoadDispatchCartEvent>(_onLoadDispatchCart);
    on<AddItemToDispatchCartEvent>(_onAddItemToDispatchCart);
    on<AddDispatchItemEvent>(_onAddDispatchItem);
    on<ClearDispatchCartEvent>(_onClearDispatchCart);
    on<RemoveItemFromDispatchCartEvent>(_onRemoveItemFromDispatchCart);
  }

  // Handler for loading the dispatch cart items
  void _onLoadDispatchCart(LoadDispatchCartEvent event, Emitter<DispatchCartState> emit) async {
    // Simulating a delay (e.g., fetching data from a server)
    await Future.delayed(Duration(seconds: 2));
    // Emitting the loaded state with the current list of items
    emit(DispatchCartLoaded(_dispatchCartItems));
  }

  // Handler for adding an item to the dispatch cart with a check for duplicates
  void _onAddItemToDispatchCart(AddItemToDispatchCartEvent event, Emitter<DispatchCartState> emit) {
    // Check if the item already exists in the cart
    bool itemExists = _dispatchCartItems.any((cartItem) =>
    cartItem.tagNumber == event.item.tagNumber &&
        cartItem.serialNumber == event.item.serialNumber);

    if (itemExists) {
      // If the item already exists, emit an error state with a message
      emit(DispatchCartError("Item has already been added to the cart."));
    } else {
      // If the item doesn't exist, add it to the cart and emit the updated state
      _dispatchCartItems.add(event.item);
      emit(DispatchCartLoaded(_dispatchCartItems));
    }
  }

  // Handler for adding an item via AddDispatchItemEvent (similar logic as AddItemToDispatchCartEvent)
  void _onAddDispatchItem(AddDispatchItemEvent event, Emitter<DispatchCartState> emit) {
    // Check if the item already exists in the cart
    bool itemExists = _dispatchCartItems.any((cartItem) =>
    cartItem.tagNumber == event.item.tagNumber &&
        cartItem.serialNumber == event.item.serialNumber);

    if (itemExists) {
      // Emit an error if the item is already in the cart
      emit(DispatchCartError("Item has already been added to the cart."));
    } else {
      // Add the item if it doesn't exist
      _dispatchCartItems.add(event.item);
      emit(DispatchCartLoaded(_dispatchCartItems));
    }
  }

  // Handler for clearing the dispatch cart
  void _onClearDispatchCart(ClearDispatchCartEvent event, Emitter<DispatchCartState> emit) {
    _dispatchCartItems.clear();
    emit(DispatchCartLoaded(_dispatchCartItems));
  }

  // Handler for removing an item from the dispatch cart
  void _onRemoveItemFromDispatchCart(RemoveItemFromDispatchCartEvent event, Emitter<DispatchCartState> emit) {
    _dispatchCartItems.remove(event.item);
    emit(DispatchCartLoaded(_dispatchCartItems));
  }
}
