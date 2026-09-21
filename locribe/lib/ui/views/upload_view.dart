import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import '../../logic/scribe_bloc/scribe_bloc.dart';
import '../../logic/scribe_bloc/scribe_event.dart';

class UploadView extends StatelessWidget {
  const UploadView({super.key});

  Future<void> _pickAudioFile(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result.isNotEmpty && result.single.path != null) {
      context.read<ScribeBloc>().add(AudioDropped(result.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _pickAudioFile(context),
        child: Container(
          width: 400,
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.cloud_upload, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Select Audio File',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '.mp3 or .wav up to 50MB',
                style: TextStyle(color: Colors.grey.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}