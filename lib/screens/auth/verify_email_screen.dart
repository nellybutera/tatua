import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  int _cooldown = 30;
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _masked {
    final parts = widget.email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return widget.email;
    return '${parts[0][0]}***@${parts[1]}';
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final ok = await ref.read(authServiceProvider).refreshVerification();
      if (!ok && mounted) showSnack(context, 'Not verified yet. Open the link in your email first.');
    } catch (e) {
      if (mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authServiceProvider).resendVerification();
      _startCooldown();
      if (mounted) showSnack(context, 'Verification link sent again.');
    } catch (e) {
      if (mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        TextButton(onPressed: () => ref.read(authServiceProvider).signOut(), child: const Text('Use another email')),
      ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_unread_rounded, size: 64, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text('Verify your email', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('We sent a link to $_masked.\nOpen it to activate your account, then come back here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const Spacer(),
            FilledButton(
              onPressed: _checking ? null : _check,
              child: _checking
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text("I've verified, continue"),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _cooldown > 0 ? null : _resend,
              child: Text(_cooldown > 0 ? 'Resend link (available in ${_cooldown}s)' : 'Resend link'),
            ),
          ]),
        ),
      ),
    );
  }
}
