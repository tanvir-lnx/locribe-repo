import 'package:equatable/equatable.dart';

abstract class DaemonEvent extends Equatable {
  const DaemonEvent();

  @override
  List<Object> get props => [];
}

class CheckDaemonStatus extends DaemonEvent {}