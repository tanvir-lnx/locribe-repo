import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/local_database.dart';
import '../../logic/scribe_bloc/scribe_bloc.dart';
import '../../logic/scribe_bloc/scribe_event.dart';
import '../../logic/vault_bloc/vault_bloc.dart';
import '../../logic/vault_bloc/vault_event.dart';
import '../../utils/pdf_export_service.dart';
import '../shared_widgets/audio_player_card.dart';
import '../shared_widgets/app_feedback.dart';

class TranscriptView extends StatelessWidget {
  final dynamic id;
  final String transcript;
  final String summary;
  final String? audioPath;

  const TranscriptView({
    super.key,
    required this.id,
    required this.transcript,
    required this.summary,
    this.audioPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        title: const Text(
          'Transcript details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF334155)),
            onPressed: () => context.read<ScribeBloc>().add(ResetWorkspace()),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildSummaryCard(context)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildTranscriptCard(context)),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(context),
                const SizedBox(height: 16),
                _buildTranscriptCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Summary',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: summary,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                color: Color(0xFF334155),
                height: 1.6,
              ),
              listBullet: const TextStyle(color: Color(0xFF334155)),
              strong: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: summary));
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () async {
                  await PdfExportService.exportToPdf(
                    transcript: transcript,
                    summary: summary,
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                onPressed: () => _deleteTranscript(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (audioPath != null) ...[
            const Text(
              'Conversation audio',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            AudioPlayerCard(audioPath: audioPath!),
            const SizedBox(height: 20),
          ],
          const Text(
            'Raw Transcript',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            transcript,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTranscript(BuildContext context) async {
    final shouldDelete = await AppFeedback.confirmDelete(context);

    if (!context.mounted) return;

    if (shouldDelete != true) {
      return;
    }

    final transcriptId = id is int ? id as int : int.tryParse(id.toString());
    if (transcriptId == null) {
      AppFeedback.show(
        context,
        message: 'Unable to delete: invalid transcript ID.',
        icon: Icons.error_outline_rounded,
        accent: const Color(0xFFF87171),
      );
      return;
    }

    await LocalDatabase.instance.deleteTranscript(transcriptId);

    if (!context.mounted) return;

    context.read<VaultBloc>().add(LoadVault());
    context.read<ScribeBloc>().add(ResetWorkspace());
    AppFeedback.show(
      context,
      message: 'Transcript deleted from your vault.',
      icon: Icons.check_rounded,
      accent: const Color(0xFF4ADE80),
    );
  }
}
