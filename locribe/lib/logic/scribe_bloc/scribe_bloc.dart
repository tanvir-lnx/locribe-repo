import 'package:flutter_bloc/flutter_bloc.dart';
import 'scribe_event.dart';
import 'scribe_state.dart';
import '../../data/qvac_api_client.dart';
import '../../data/local_database.dart';

class ScribeBloc extends Bloc<ScribeEvent, ScribeState> {
  final QvacApiClient apiClient;

  ScribeBloc({required this.apiClient}) : super(ScribeIdle()) {
    on<AudioDropped>(_onAudioDropped);
    on<ResetWorkspace>((event, emit) => emit(ScribeIdle()));
    on<LoadExistingTranscript>(_onLoadExistingTranscript);
  }

  void _onLoadExistingTranscript(LoadExistingTranscript event, Emitter<ScribeState> emit) {
    emit(ScribeComplete(
      id: event.id, // <-- Pushes loaded ID to UI
      rawTranscript: event.rawTranscript,
      summary: event.summary,
    ));
  }

  Future<void> _onAudioDropped(AudioDropped event, Emitter<ScribeState> emit) async {
    try {
      final isReady = await apiClient.checkStatus();
      if (!isReady) {
        emit(const ScribeError("Daemon is offline. Please start the Python server."));
        return;
      }

      emit(const ScribeProcessing("Transcribing audio locally..."));
      final transcriptText = await apiClient.transcribeAudio(event.filePath);

      if (transcriptText.trim().isEmpty) {
        emit(const ScribeError("Transcription returned empty."));
        return;
      }

      emit(const ScribeProcessing("Generating executive summary..."));
      final summaryText = await apiClient.summarizeText(transcriptText);

      emit(const ScribeProcessing("Saving to Audio Vault..."));
      
      final fileName = event.filePath.split('/').last;
      
      // Capture the ID created by SQLite
      final savedId = await LocalDatabase.instance.saveTranscript(
        fileName, 
        transcriptText, 
        summaryText
      );

      emit(ScribeComplete(
        id: savedId, // <-- Pushes brand new ID to UI
        rawTranscript: transcriptText, 
        summary: summaryText,
      ));

    } catch (e) {
      emit(ScribeError("Local inference failed: ${e.toString()}"));
    }
  }
}