import 'package:equatable/equatable.dart';

abstract class DaemonState extends Equatable {
  const DaemonState();

  @override
  List<Object> get props => [];
}

class DaemonInitial extends DaemonState {}

class DaemonChecking extends DaemonState {}

class DaemonOnline extends DaemonState {}

class DaemonOffline extends DaemonState {}