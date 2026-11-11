import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/incident.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../shared/incident_details_screen.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key, required this.onOpenTab, required this.onReport});
  final ValueChanged<int> onOpenTab;
  final VoidCallback onReport;

  void _open(BuildContext context, Incident i) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailsScreen(incidentId: i.id)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final mine = ref.watch(myIncidentsProvider);
    final recent = ref.watch(recentIncidentsProvider);
    final myIds = ref.watch(myReportIdsProvider).value ?? const <String>[];

    int count(IncidentStatus s) => (mine.value ?? []).where((i) => i.status == s).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recentIncidentsProvider),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
          // Greeting
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hello, ${user?.firstName ?? 'there'} 👋', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text('Help make our campus better.', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primarySoft,
              child: Text((user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 18),

          // Hero card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Spotted an issue on campus?',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Report it in under a minute and follow it until it is fixed.',
                  style: TextStyle(color: Color(0xFFDDF1EE), fontSize: 13)),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF3D2B03),
                  minimumSize: const Size(0, 44),
                ),
                onPressed: onReport,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Report an issue'),
              ),
            ]),
          ),
          const SizedBox(height: 22),

          // Summary tiles
          _SectionHeader('Your reports', onSeeAll: () => onOpenTab(1)),
          Row(children: [
            _StatTile(label: 'Total', value: mine.value?.length ?? 0, icon: Icons.description_rounded, color: AppColors.primary),
            _StatTile(label: 'In progress', value: count(IncidentStatus.inProgress), icon: Icons.build_rounded, color: IncidentStatus.inProgress.color),
            _StatTile(label: 'Resolved', value: count(IncidentStatus.resolved), icon: Icons.check_circle_rounded, color: IncidentStatus.resolved.color),
            _StatTile(label: 'Submitted', value: count(IncidentStatus.submitted), icon: Icons.send_rounded, color: IncidentStatus.submitted.color),
          ]),
          const SizedBox(height: 22),

          // My recent reports
          _SectionHeader('Recent reports', onSeeAll: () => onOpenTab(1)),
          mine.when(
            loading: () => const ListSkeleton(),
            error: (e, _) => ErrorView(e),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'No reports yet',
                    message: 'Tap "Report an issue" when you notice something that needs fixing.')
                : Column(children: [
                    for (final i in list.take(3))
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: IncidentCard(incident: i, onTap: () => _open(context, i))),
                  ]),
          ),
          const SizedBox(height: 12),

          // Campus activity
          _SectionHeader('Happening around campus', onSeeAll: () => onOpenTab(3)),
          recent.when(
            loading: () => const ListSkeleton(count: 2),
            error: (e, _) => ErrorView(e),
            data: (list) {
              final others = list.where((i) => !myIds.contains(i.id)).take(2).toList();
              if (others.isEmpty) {
                return const EmptyState(icon: Icons.celebration_rounded, title: 'All quiet on campus');
              }
              return Column(children: [
                for (final i in others)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: IncidentCard(incident: i, onTap: () => _open(context, i))),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ]),
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
      );
}
