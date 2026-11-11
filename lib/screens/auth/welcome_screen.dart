import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const AppLogo(size: 32),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(99)),
                child: const Text('Built for the ALU community',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
              ),
            ]),
            const Spacer(),
            Center(
              child: Container(
                width: 220,
                height: 180,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(28)),
                child: const Stack(alignment: Alignment.center, children: [
                  Icon(Icons.home_work_rounded, size: 110, color: AppColors.primary),
                  Positioned(top: 18, right: 22, child: Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 32)),
                  Positioned(top: 18, left: 22, child: Icon(Icons.add_circle_rounded, color: AppColors.primaryDark, size: 32)),
                ]),
              ),
            ),
            const Spacer(),
            const Text('YOUR CAMPUS, CARED FOR',
                style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('See it. Report it.\nWe\'ll help fix it.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 28, height: 1.2)),
            const SizedBox(height: 8),
            Text('Report campus issues in seconds and follow every update through to resolution.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Get started'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('I already have an account'),
            ),
          ]),
        ),
      ),
    );
  }
}
