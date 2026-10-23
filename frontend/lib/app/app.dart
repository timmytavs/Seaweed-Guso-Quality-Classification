import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/classification_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/seaweed_language_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/landing/landing_screen.dart';
import '../services/auth_service.dart';
import 'theme.dart';

class GusoApp extends StatelessWidget {
  const GusoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClassificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SeaweedLanguageProvider()),
      ],
      child: MaterialApp(
        title: 'GUSO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _SessionStartupGate(),
      ),
    );
  }
}

class _SessionStartupGate extends StatefulWidget {
  const _SessionStartupGate();

  @override
  State<_SessionStartupGate> createState() => _SessionStartupGateState();
}

class _SessionStartupGateState extends State<_SessionStartupGate> {
  late final Future<bool> _sessionIsValid = _checkExistingSession();

  Future<bool> _checkExistingSession() async {
    try {
      // Chrome refresh clears in-memory state: restore the stored JWT first.
      final restored = await AuthService.restoreSession();
      debugPrint('gUSo startup: session restored = $restored');
      if (!restored) return false;

      final isValid = await const AuthService().validateSession();
      debugPrint('gUSo startup: session valid = $isValid');
      if (!isValid || !mounted) return false;

      // Load PostgreSQL history while the authenticated session is active.
      final provider = context.read<ClassificationProvider>();
      await provider.loadSavedHistory();
      if (!mounted) return false;

      debugPrint(
        'gUSo startup: saved summaries = '
        '${provider.savedSummaries.length}; '
        'full session records = ${provider.records.length}',
      );
      if (provider.historyError != null) {
        debugPrint('gUSo startup: history load error = ${provider.historyError}');
      }

      // The session is still valid even if History could not load.
      // The History UI will show its error and allow a retry.
      return true;
    } catch (error) {
      debugPrint('gUSo startup: session check failed = $error');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionIsValid,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true
            ? const HomeScreen()
            : const LandingScreen();
      },
    );
  }
}
