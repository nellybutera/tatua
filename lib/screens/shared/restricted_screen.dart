import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

/// Shown when the signed-in account is not allowed to use (part of) the app.
class RestrictedScreen extends ConsumerWidget {
  const RestrictedScreen({super.key, required this.message, this.canGoBack = false});
  final String message;
  final bool canGoBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                child: const Icon(Icons.lock_rounded, size: 56, color: AppColors.error),
              ),
            ),
            const SizedBox(height: 20),
            Text('Access restricted', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => canGoBack ? Navigator.pop(context) : ref.read(authServiceProvider).signOut(),
              child: Text(canGoBack ? 'Go back' : 'Sign out'),
            ),
          ]),
        ),
      ),
    );
  }
}
