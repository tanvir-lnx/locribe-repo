import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../logic/scribe_bloc/scribe_bloc.dart';
import '../../logic/scribe_bloc/scribe_event.dart';
import '../../logic/vault_bloc/vault_bloc.dart';
import '../../logic/vault_bloc/vault_event.dart';
import '../../utils/pdf_export_service.dart';

class TranscriptView extends StatelessWidget {
  final int id; // <-- Added ID tracking
  final String transcript;
  final String summary;

  const TranscriptView({
    super.key,
    required this.id, 
    required this.transcript,
    required this.summary,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Executive Summary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.read<ScribeBloc>().add(ResetWorkspace()),
                    tooltip: 'Close and start over',
                  )
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Markdown Summary
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Markdown(
                          data: summary,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: const TextStyle(fontSize: 15, height: 1.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column: Raw Transcript
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Raw Transcript', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Text(
                                transcript,
                                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // The Floating Action Bar (Bottom Right)
        Positioned(
          bottom: 30,
          right: 30,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: Colors.white),
                  tooltip: 'Copy Summary',
                  onPressed: () => _copyToClipboard(context, summary),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.white),
                  tooltip: 'Export PDF',
                  onPressed: () async {
                    await PdfExportService.exportToPdf(transcript: transcript, summary: summary);
                  },
                ),
                Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 4)),
                
                // DELETION LOGIC WIRED HERE
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: 'Delete from Vault',
                  onPressed: () {
                    // 1. Delete from SQLite
                    context.read<VaultBloc>().add(DeleteVaultItem(id));
                    
                    // 2. Clear the screen
                    context.read<ScribeBloc>().add(ResetWorkspace());
                    
                    // 3. Notify the user
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transcript removed from Vault.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}