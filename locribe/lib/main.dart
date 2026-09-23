import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:locribe/logic/daemon_bloc/daemon_bloc.dart';
import 'package:locribe/logic/daemon_bloc/daemon_event.dart';
import 'package:locribe/logic/vault_bloc/vault_bloc.dart';
import 'package:locribe/logic/vault_bloc/vault_event.dart';
import 'data/qvac_api_client.dart';
import 'logic/scribe_bloc/scribe_bloc.dart';
import 'ui/responsive/responsive_layout.dart';
import 'ui/theme/app_theme.dart';

void main() {
  final apiClient = QvacApiClient();
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ScribeBloc(apiClient: apiClient),
        ),
        BlocProvider(
          create: (_) => DaemonBloc(apiClient: apiClient)..add(CheckDaemonStatus()),
          // Removed the rogue child property that was hiding here!
        ),
        BlocProvider(
          create: (_) => VaultBloc()..add(LoadVault()), 
        ),
      ], 
      child: const LoCribeApp(),
    )
  );
}

class LoCribeApp extends StatelessWidget {
  const LoCribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoCribe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ResponsiveLayout(),
    );
  }
}