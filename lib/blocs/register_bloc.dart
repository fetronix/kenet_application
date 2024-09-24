import 'package:flutter_bloc/flutter_bloc.dart';

abstract class RegisterEvent {}

class RegisterButtonPressed extends RegisterEvent {
  final String username;
  final String email;
  final String password;

  RegisterButtonPressed({required this.username, required this.email, required this.password});
}

abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {}

class RegisterFailure extends RegisterState {
  final String message;

  RegisterFailure({required this.message});
}

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc() : super(RegisterInitial());

  @override
  Stream<RegisterState> mapEventToState(RegisterEvent event) async* {
    if (event is RegisterButtonPressed) {
      yield RegisterLoading();
      try {
        // Simulate a network call
        await Future.delayed(Duration(seconds: 2));
        // Here you would normally call your API for registration
        yield RegisterSuccess(); // Assuming success
      } catch (error) {
        yield RegisterFailure(message: 'Registration failed');
      }
    }
  }
}
