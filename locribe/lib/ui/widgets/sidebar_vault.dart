import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/vault_bloc/vault_bloc.dart';
import '../../logic/vault_bloc/vault_state.dart';
import '../../logic/scribe_bloc/scribe_bloc.dart';
import '../../logic/scribe_bloc/scribe_event.dart';

class SidebarVault extends StatelessWidget {
  const SidebarVault({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultBloc, VaultState>(
      builder: (context, state) {
        if (state is VaultLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2));
        }
        
        if (state is VaultLoaded) {
          if (state.transcripts.isEmpty) {
            return const Center(
              child: Text('No saved transcripts.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            );
          }

          return ListView.builder(
            itemCount: state.transcripts.length,
            itemBuilder: (context, index) {
              final item = state.transcripts[index];
              return ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.grey, size: 20),
                title: Text(
                  item['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  item['created_at'].toString().split('T').first,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                onTap: () {
                  context.read<ScribeBloc>().add(
                    LoadExistingTranscript(
                      id: item['id'], // <-- Passes ID from SQLite
                      rawTranscript: item['raw_transcript'],
                      summary: item['summary'],
                    ),
                  );
                },
              );
            },
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}