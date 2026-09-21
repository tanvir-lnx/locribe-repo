import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TranscriptView extends StatelessWidget {
  final dynamic id;
  final String transcript;
  final String summary;

  const TranscriptView({
    super.key,
    required this.id,
    required this.transcript,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Executive Summary', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              // Safely pops if pushed. If rendered via BLoC at the root, routes home.
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop/Wide layout
          if (constraints.maxWidth > 600) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildSummaryCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildTranscriptCard()),
                ],
              ),
            );
          }
          // Mobile layout
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildTranscriptCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Executive Summary',
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: summary,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.6),
              listBullet: const TextStyle(color: Colors.white70),
              strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 20), 
                onPressed: () {}
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white54, size: 20), 
                onPressed: () {}
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), 
                onPressed: () {}
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Raw Transcript',
            style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            transcript,
            style: const TextStyle(fontSize: 14, color: Colors.white54, height: 1.5),
          ),
        ],
      ),
    );
  }
}