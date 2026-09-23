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
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B6CE7),
              strokeWidth: 2,
            ),
          );
        }

        if (state is VaultLoaded) {
          if (state.transcripts.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No saved transcripts yet.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            );
          }

          return ListView.separated(
            itemCount: state.transcripts.length,
            separatorBuilder: (_, index) => const Divider(
              color: Color(0xFFE5EAF2),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final item = state.transcripts[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFF2B6CE7),
                    size: 18,
                  ),
                ),
                title: Text(
                  item['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  item['created_at'].toString().split('T').first,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                onTap: () {
                  context.read<ScribeBloc>().add(
                    LoadExistingTranscript(
                      id: item['id'],
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