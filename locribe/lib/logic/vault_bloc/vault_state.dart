import 'package:equatable/equatable.dart';

abstract class VaultState extends Equatable {
  // Added the const constructor here to fix the inheritance error
  const VaultState();

  @override
  List<Object> get props => [];
}

class VaultLoading extends VaultState {}

class VaultLoaded extends VaultState {
  final List<Map<String, dynamic>> transcripts;
  const VaultLoaded(this.transcripts);

  @override
  List<Object> get props => [transcripts];
}