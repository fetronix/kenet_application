import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LoginEvent {}

class LoginButtonPressed extends LoginEvent {
  final String email;
  final String password;

  LoginButtonPressed({required this.email, required this.password});
}

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginFailure extends LoginState {
  final String message;

  LoginFailure({required this.message});
}

class LoginSuccess extends LoginState {}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial());

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is LoginButtonPressed) {
      yield LoginLoading();

      try {
        // Simulate an authentication process
        await Future.delayed(Duration(seconds: 2));

        if (event.email == "user@gmail.com" && event.password == "password") {
          yield LoginSuccess();
        } else {
          yield LoginFailure(message: "Invalid email or password");
        }
      } catch (e) {
        yield LoginFailure(message: "An error occurred. Please try again.");
      }
    }
  }
}
