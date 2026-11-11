import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // gotta wake Firebase up before anything else touches it
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ProviderScope = the box where all the Riverpod state lives. no box, no providers.
  runApp(const ProviderScope(child: TatuaApp()));
}

class TatuaApp extends StatelessWidget {
  const TatuaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tatua',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // no login page hardcoded here. AuthGate figures out where you belong
      home: const AuthGate(),
    );
  }
}
