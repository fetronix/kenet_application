import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AboutEvent {}

class LoadAboutEvent extends AboutEvent {}

abstract class AboutState {}

class AboutLoading extends AboutState {}

class AboutLoaded extends AboutState {
  final String info;

  AboutLoaded(this.info);
}

class AboutError extends AboutState {
  final String message;

  AboutError(this.message);
}

class AboutBloc extends Bloc<AboutEvent, AboutState> {
  AboutBloc() : super(AboutLoading());

  @override
  Stream<AboutState> mapEventToState(AboutEvent event) async* {
    if (event is LoadAboutEvent) {
      yield AboutLoading();
      try {
        // Simulate a delay and fetch information
        await Future.delayed(Duration(seconds: 2));
        yield AboutLoaded('Information about K.M.A.S');
      } catch (e) {
        yield AboutError('Failed to load about information');
      }
    }
  }
}
