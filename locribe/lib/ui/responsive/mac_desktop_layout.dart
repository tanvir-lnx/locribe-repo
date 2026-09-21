import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/scribe_bloc/scribe_bloc.dart';
import '../../logic/scribe_bloc/scribe_state.dart';
import '../../logic/scribe_bloc/scribe_event.dart';
import '../../logic/daemon_bloc/daemon_bloc.dart';
import '../../logic/daemon_bloc/daemon_state.dart';
import '../../logic/daemon_bloc/daemon_event.dart';
import '../views/upload_view.dart';
import '../views/transcript_view.dart';
import '../widgets/sidebar_vault.dart';
import '../../logic/vault_bloc/vault_bloc.dart';
import '../../logic/vault_bloc/vault_event.dart';

class MacDesktopLayout extends StatelessWidget {
  const MacDesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Pane: Sidebar
          Container(
            width: 250,
            color: const Color(0xFF181818),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 40, left: 20, bottom: 20),
                  child: Text('LoCribe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('New Scribe'),
                  selected: true,
                  selectedTileColor: Colors.grey.withOpacity(0.1),
                  onTap: () {
                    context.read<ScribeBloc>().add(ResetWorkspace());
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                  child: Text('AUDIO VAULT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                BlocListener<ScribeBloc, ScribeState>(
                  listener: (context, state) {
                    if (state is ScribeComplete) {
                      context.read<VaultBloc>().add(LoadVault());
                    }
                  },
                  child: const Expanded(child: SidebarVault()),
                ),

                // Dynamic Daemon Status Indicator
                BlocBuilder<DaemonBloc, DaemonState>(
                  builder: (context, state) {
                    Color statusColor = Colors.grey;
                    String statusText = 'Checking Daemon...';

                    if (state is DaemonOnline) {
                      statusColor = Colors.greenAccent;
                      statusText = 'Daemon Ready';
                    } else if (state is DaemonOffline) {
                      statusColor = Colors.redAccent;
                      statusText = 'Daemon Offline';
                    } else if (state is DaemonChecking) {
                      statusColor = Colors.orangeAccent;
                    }

                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: statusColor, size: 12),
                          const SizedBox(width: 8),
                          Text(statusText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const Spacer(),
                          InkWell(
                            onTap: () => context.read<DaemonBloc>().add(CheckDaemonStatus()),
                            child: const Icon(Icons.refresh, color: Colors.grey, size: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Right Pane: Main Content Area
          Expanded(
            child: BlocBuilder<ScribeBloc, ScribeState>(
              builder: (context, state) {
                if (state is ScribeIdle) return const UploadView();
                if (state is ScribeProcessing) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 24),
                        Text(state.statusMessage, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                if (state is ScribeComplete) {
                  return TranscriptView(
                    id: state.id, // <-- Passes ID down to the view
                    transcript: state.rawTranscript,
                    summary: state.summary,
                  );
                }
                if (state is ScribeError) {
                  return Center(child: Text(state.errorMessage, style: const TextStyle(color: Colors.red)));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}