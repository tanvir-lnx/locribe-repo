import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/scribe_bloc/scribe_bloc.dart';
import '../../logic/scribe_bloc/scribe_state.dart';
import '../../logic/scribe_bloc/scribe_event.dart';
import '../../logic/daemon_bloc/daemon_bloc.dart';
import '../../logic/daemon_bloc/daemon_state.dart';
import '../../logic/daemon_bloc/daemon_event.dart';
import '../../logic/vault_bloc/vault_bloc.dart';
import '../../logic/vault_bloc/vault_event.dart';
import '../views/upload_view.dart';
import '../views/transcript_view.dart';
import '../widgets/sidebar_vault.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoCribe', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Minimalist Daemon Status in AppBar
          BlocBuilder<DaemonBloc, DaemonState>(
            builder: (context, state) {
              Color statusColor = Colors.grey;
              if (state is DaemonOnline) statusColor = Colors.greenAccent;
              if (state is DaemonOffline) statusColor = Colors.redAccent;
              if (state is DaemonChecking) statusColor = Colors.orangeAccent;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: Colors.grey),
                      onPressed: () => context.read<DaemonBloc>().add(CheckDaemonStatus()),
                      tooltip: 'Refresh Daemon Status',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      
      // BlocListener automatically jumps to the Scribe tab when a transcript finishes or is loaded
      body: BlocListener<ScribeBloc, ScribeState>(
        listener: (context, state) {
          if (state is ScribeComplete) {
            setState(() => _currentIndex = 0);
            // Silently update the vault list in the background if a new one just finished processing
            context.read<VaultBloc>().add(LoadVault()); 
          }
        },
        child: _currentIndex == 0
            ? _buildScribeView()
            : const SidebarVault(), // Reusing the Sidebar list as a full-screen mobile page!
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF181818),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic), 
            label: 'Scribe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder), 
            label: 'Vault',
          ),
        ],
      ),
    );
  }

  Widget _buildScribeView() {
    return BlocBuilder<ScribeBloc, ScribeState>(
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
            id: state.id,
            transcript: state.rawTranscript,
            summary: state.summary,
          );
        }
        
        if (state is ScribeError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage, 
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.read<ScribeBloc>().add(ResetWorkspace()),
                    child: const Text('Try Again'),
                  )
                ],
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}