import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/local_database.dart';
import 'vault_event.dart';
import 'vault_state.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  VaultBloc() : super(VaultLoading()) {
    on<LoadVault>(_onLoadVault);
    on<DeleteVaultItem>(_onDeleteVaultItem); // <-- Wire up deletion
  }

  Future<void> _onLoadVault(LoadVault event, Emitter<VaultState> emit) async {
    emit(VaultLoading());
    try {
      final transcripts = await LocalDatabase.instance.fetchAllTranscripts();
      emit(VaultLoaded(transcripts));
    } catch (e) {
      emit(const VaultLoaded([])); 
    }
  }

  Future<void> _onDeleteVaultItem(DeleteVaultItem event, Emitter<VaultState> emit) async {
    await LocalDatabase.instance.deleteTranscript(event.id);
    add(LoadVault()); // Instantly refresh the sidebar list after deleting
  }
}