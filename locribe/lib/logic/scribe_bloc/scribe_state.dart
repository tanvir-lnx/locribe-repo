import 'package:equatable/equatable.dart';

abstract class ScribeState extends Equatable {
  const ScribeState();
  
  @override
  List<Object> get props => [];
}

class ScribeIdle extends ScribeState {}

class ScribeProcessing extends ScribeState {
  final String statusMessage;
  const ScribeProcessing(this.statusMessage);

  @override
  List<Object> get props => [statusMessage];
}

class ScribeComplete extends ScribeState {
  final int id; // <-- Added ID tracking
  final String rawTranscript;
  final String summary;
  
  const ScribeComplete({
    required this.id,
    required this.rawTranscript, 
    required this.summary,
  });

  @override
  List<Object> get props => [id, rawTranscript, summary];
}

class ScribeError extends ScribeState {
  final String errorMessage;
  const ScribeError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}