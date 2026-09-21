import 'package:equatable/equatable.dart';

abstract class VaultEvent extends Equatable {
  // Added the const constructor here to fix the inheritance error
  const VaultEvent();

  @override
  List<Object> get props => [];
}

class LoadVault extends VaultEvent {}

class DeleteVaultItem extends VaultEvent {
  final int id;
  const DeleteVaultItem(this.id);

  @override
  List<Object> get props => [id];
}