import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../logic/scribe_bloc/scribe_bloc.dart';
import '../../logic/scribe_bloc/scribe_event.dart';
import '../shared_widgets/app_feedback.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key});

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartedAt;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile(BuildContext context) async {
    final scribeBloc = context.read<ScribeBloc>();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (!context.mounted) return;
    if (result.isNotEmpty && result.single.path != null) {
      scribeBloc.add(AudioDropped(result.single.path!));
    }
  }

  Future<void> _toggleRecording(BuildContext context) async {
    final scribeBloc = context.read<ScribeBloc>();
    if (_isRecording) {
      final path = await _recorder.stop();
      if (!context.mounted) return;
      setState(() {
        _isRecording = false;
        _recordingStartedAt = null;
      });
      if (path != null) {
        scribeBloc.add(AudioDropped(path));
      }
      return;
    }

    try {
      if (!await _recorder.hasPermission()) {
        throw StateError('Microphone permission was not granted.');
      }
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/locribe-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (!context.mounted) return;
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _recordingStartedAt = DateTime.now();
      });
      _updateRecordingDuration();
    } catch (error) {
      if (!context.mounted) return;
      AppFeedback.show(
        context,
        message: 'Unable to start recording: $error',
        icon: Icons.mic_off_outlined,
        accent: const Color(0xFFF87171),
      );
    }
  }

  void _updateRecordingDuration() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_isRecording || _recordingStartedAt == null) return;
      setState(() {
        _recordingDuration = DateTime.now().difference(_recordingStartedAt!);
      });
      _updateRecordingDuration();
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5EAF2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRecording
                  ? CupertinoIcons.waveform
                  : CupertinoIcons.cloud_upload,
              size: 48,
              color: _isRecording
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF2B6CE7),
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording ? 'Recording conversation' : 'Add a conversation',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? _formatDuration(_recordingDuration)
                  : 'Record a conversation or choose an audio file',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickAudioFile(context),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Choose file'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _toggleRecording(context),
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop & transcribe' : 'Record'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isRecording
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2B6CE7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
