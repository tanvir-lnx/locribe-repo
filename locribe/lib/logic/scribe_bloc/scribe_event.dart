import 'package:equatable/equatable.dart';

abstract class ScribeEvent extends Equatable {
  const ScribeEvent();

  @override
  List<Object> get props => [];
}

class AudioDropped extends ScribeEvent {
  final String filePath;
  const AudioDropped(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class LoadExistingTranscript extends ScribeEvent {
  final int id; // <-- Passed when clicking the sidebar
  final String rawTranscript;
  final String summary;

  const LoadExistingTranscript({
    required this.id,
    required this.rawTranscript,
    required this.summary,
  });

  @override
  List<Object> get props => [id, rawTranscript, summary];
}

class ResetWorkspace extends ScribeEvent {}