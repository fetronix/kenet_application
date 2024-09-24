import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class ConsignmentsEvent {}

// States
abstract class ConsignmentsState {}

class ConsignmentsInitial extends ConsignmentsState {}

// Bloc
class ConsignmentsBloc extends Bloc<ConsignmentsEvent, ConsignmentsState> {
  ConsignmentsBloc() : super(ConsignmentsInitial());
}
