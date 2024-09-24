import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class AssetsEvent {}

class LoadAssetsEvent extends AssetsEvent {}

// States
abstract class AssetsState {}

class AssetsLoading extends AssetsState {}

class AssetsLoaded extends AssetsState {
  final List<String> assets;

  AssetsLoaded(this.assets);
}

class AssetsError extends AssetsState {}

// Bloc
class AssetsBloc extends Bloc<AssetsEvent, AssetsState> {
  AssetsBloc() : super(AssetsLoading());

  @override
  Stream<AssetsState> mapEventToState(AssetsEvent event) async* {
    if (event is LoadAssetsEvent) {
      // Simulate loading data
      await Future.delayed(Duration(seconds: 2));
      yield AssetsLoaded(['Asset 1', 'Asset 2', 'Asset 3']);
    }
  }
}
