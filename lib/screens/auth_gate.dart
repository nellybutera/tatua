import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../providers/providers.dart';
import 'auth/verify_email_screen.dart';
import 'auth/welcome_screen.dart';
import 'shared/restricted_screen.dart';
import 'staff/staff_shell.dart';
import 'student/student_shell.dart';

/// Creates the student's Firestore profile once their email is verified.
final _studentProfileBootstrap = FutureProvider.family<void, String>((ref, uid) async {
  final user = ref.read(firebaseAuthProvider).currentUser;
  if (user != null && user.uid == uid) {
    await ref.read(authServiceProvider).ensureStudentProfile(user);
  }
});

/// Decides which part of the app to show based on who is signed in.
///
///   signed out                  -> Welcome
///   student, email unverified   -> Verify email
///   not an ALU email            -> Access restricted
///   role == staff               -> Staff app
///   otherwise                   -> Student app
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    return auth.when(
      loading: () => const _Loading(),
      error: (e, _) => const WelcomeScreen(),
      data: (user) {
        if (user == null) return const WelcomeScreen();
        final email = user.email ?? '';

        if (AppConstants.isStudentEmail(email)) {
          if (!user.emailVerified) return VerifyEmailScreen(email: email);
          final boot = ref.watch(_studentProfileBootstrap(user.uid));
          if (boot.isLoading) return const _Loading();
          if (boot.hasError) {
            return _RetryScreen(onRetry: () => ref.invalidate(_studentProfileBootstrap(user.uid)));
          }
          return _byRole(ref, user);
        }
        if (AppConstants.isStaffEmail(email)) return _byRole(ref, user, staffEmail: true);

        return const RestrictedScreen(
          message: 'Tatua is only available to ALU students and staff. Please sign in with your ALU email.',
        );
      },
    );
  }

  Widget _byRole(WidgetRef ref, User user, {bool staffEmail = false}) {
    final profile = ref.watch(appUserProvider);
    return profile.when(
      loading: () => const _Loading(),
      error: (e, _) => RestrictedScreen(message: 'Could not load your profile. ($e)'),
      data: (appUser) {
        if (appUser == null) {
          return staffEmail
              ? const RestrictedScreen(
                  message: 'Your staff account has not been set up yet. Ask an administrator to grant staff access.')
              : const _Loading();
        }
        if (appUser.isStaff && staffEmail) return const StaffShell();
        if (staffEmail) {
          return const RestrictedScreen(message: 'This account does not have staff access.');
        }
        return const StudentShell();
      },
    );
  }
}

class _RetryScreen extends ConsumerWidget {
  const _RetryScreen({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_rounded, size: 56),
              const SizedBox(height: 12),
              const Text('We could not finish setting up your account.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
              TextButton(onPressed: () => ref.read(authServiceProvider).signOut(), child: const Text('Sign out')),
            ]),
          ),
        ),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
