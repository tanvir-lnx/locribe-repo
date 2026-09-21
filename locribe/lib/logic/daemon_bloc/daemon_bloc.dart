import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/qvac_api_client.dart';
import 'daemon_event.dart';
import 'daemon_state.dart';

class DaemonBloc extends Bloc<DaemonEvent, DaemonState> {
  final QvacApiClient apiClient;

  DaemonBloc({required this.apiClient}) : super(DaemonInitial()) {
    on<CheckDaemonStatus>(_onCheckStatus);
  }

  Future<void> _onCheckStatus(CheckDaemonStatus event, Emitter<DaemonState> emit) async {
    emit(DaemonChecking());
    
    // Ping the Python server
    final isOnline = await apiClient.checkStatus();
    
    if (isOnline) {
      emit(DaemonOnline());
    } else {
      emit(DaemonOffline());
    }
  }
}