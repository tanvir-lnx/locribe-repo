import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/daemon_bloc/daemon_bloc.dart';
import '../../logic/daemon_bloc/daemon_event.dart';
import '../../logic/daemon_bloc/daemon_state.dart';
import '../../logic/scribe_bloc/scribe_bloc.dart';
import '../../logic/scribe_bloc/scribe_event.dart';
import '../../logic/scribe_bloc/scribe_state.dart';
import '../../logic/vault_bloc/vault_bloc.dart';
import '../../logic/vault_bloc/vault_event.dart';
import '../views/transcript_view.dart';
import '../views/upload_view.dart';
import '../widgets/sidebar_vault.dart';

class MacDesktopLayout extends StatefulWidget {
  const MacDesktopLayout({super.key});

  @override
  State<MacDesktopLayout> createState() => _MacDesktopLayoutState();
}

class _MacDesktopLayoutState extends State<MacDesktopLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 920;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F7FB),
          endDrawer: isCompact
              ? Drawer(
                  child: SafeArea(
                    child: SizedBox(width: 320, child: _buildSidebarContent()),
                  ),
                )
              : null,
          body: SafeArea(
            child: isCompact
                ? _buildMainPane(showMenuButton: true)
                : Row(
                    children: [
                      SizedBox(width: 300, child: _buildSidebarContent()),
                      Expanded(child: _buildMainPane(showMenuButton: false)),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5EAF2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFEFF4FE),
                  child: Icon(Icons.mic, color: Color(0xFF2B6CE7), size: 18),
                ),
                SizedBox(width: 10),
                Text(
                  'LoCribe',
                  style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: () => context.read<ScribeBloc>().add(ResetWorkspace()),
              icon: const Icon(Icons.add),
              label: const Text('New transcription'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF2B6CE7),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: Text(
              'RECORDINGS',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          BlocListener<ScribeBloc, ScribeState>(
            listener: (context, state) {
              if (state is ScribeComplete) {
                context.read<VaultBloc>().add(LoadVault());
              }
            },
            child: const Expanded(child: SidebarVault()),
          ),
          BlocBuilder<DaemonBloc, DaemonState>(
            builder: (context, state) {
              Color statusColor = const Color(0xFF94A3B8);
              String statusText = 'Checking service...';

              if (state is DaemonOnline) {
                statusColor = const Color(0xFF16A34A);
                statusText = 'Service ready';
              } else if (state is DaemonOffline) {
                statusColor = const Color(0xFFDC2626);
                statusText = 'Service offline';
              } else if (state is DaemonChecking) {
                statusColor = const Color(0xFFF59E0B);
              }

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5EAF2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 10),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          context.read<DaemonBloc>().add(CheckDaemonStatus()),
                      child: const Icon(
                        Icons.refresh,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainPane({required bool showMenuButton}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EAF2)),
            ),
            child: Row(
              children: [
                if (showMenuButton) ...[
                  IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                    icon: const Icon(Icons.menu_rounded),
                    color: const Color(0xFF334155),
                    tooltip: 'Open recordings',
                  ),
                  const SizedBox(width: 8),
                ],
                const Expanded(
                  child: Text(
                    'Workspace',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (!showMenuButton)
                  const Text(
                    'Conversation workspace',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                if (showMenuButton) ...[
                  const SizedBox(width: 8),
                  _buildTopStatusPill(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: BlocBuilder<ScribeBloc, ScribeState>(
                builder: (context, state) {
                  if (state is ScribeIdle) return const UploadView();
                  if (state is ScribeProcessing) {
                    return Center(
                      child: Container(
                        width: 380,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF2B6CE7),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Transcribing audio...',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is ScribeComplete) {
                    return TranscriptView(
                      id: state.id,
                      transcript: state.rawTranscript,
                      summary: state.summary,
                      audioPath: state.audioPath,
                    );
                  }
                  if (state is ScribeError) {
                    return Center(
                      child: Text(
                        state.errorMessage,
                        style: const TextStyle(color: Color(0xFFDC2626)),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusPill() {
    return BlocBuilder<DaemonBloc, DaemonState>(
      builder: (context, state) {
        Color statusColor = const Color(0xFF94A3B8);
        String statusText = 'Checking';

        if (state is DaemonOnline) {
          statusColor = const Color(0xFF16A34A);
          statusText = 'Online';
        } else if (state is DaemonOffline) {
          statusColor = const Color(0xFFDC2626);
          statusText = 'Offline';
        } else if (state is DaemonChecking) {
          statusColor = const Color(0xFFF59E0B);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.read<DaemonBloc>().add(CheckDaemonStatus()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EAF2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: statusColor, size: 10),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
