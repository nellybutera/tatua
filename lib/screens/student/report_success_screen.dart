import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../shared/incident_details_screen.dart';

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key, required this.incidentId});
  final String incidentId;

  /// Short human-friendly reference shown to the student.
  String get reference => '#INC-${incidentId.substring(0, 6).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 64, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Report submitted', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Thanks for helping improve campus. Staff will review it soon and you can follow every update.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Text('Reference $reference', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => IncidentDetailsScreen(incidentId: incidentId))),
              child: const Text('Track my report'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to home')),
          ]),
        ),
      ),
    );
  }
}
