import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/incident.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../shared/incident_details_screen.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  static bool _isOpen(Incident i) => i.status != IncidentStatus.resolved && i.status != IncidentStatus.rejected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final recent = ref.watch(recentIncidentsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        title: Row(children: [
          Text('Hi, ${user?.firstName ?? ''}'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(99)),
            child: const Text('Staff', style: TextStyle(fontSize: 11, color: Color(0xFF3D2B03), fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
      body: recent.when(
        loading: () => const Padding(padding: EdgeInsets.all(16), child: ListSkeleton(count: 5)),
        error: (e, _) => ErrorView(e),
        data: (all) {
          final now = DateTime.now();
          final today = all.where((i) => now.difference(i.createdAt).inHours < 24).length;
          final open = all.where(_isOpen).toList();
          final inProgress = all.where((i) => i.status == IncidentStatus.inProgress).length;
          final resolvedWeek = all
              .where((i) => i.status == IncidentStatus.resolved && now.difference(i.updatedAt).inDays < 7)
              .length;

          // Needs attention: open reports, high urgency first, then oldest first.
          final attention = [...open]
            ..sort((a, b) {
              final u = b.urgency.index.compareTo(a.urgency.index);
              return u != 0 ? u : a.createdAt.compareTo(b.createdAt);
            });

          final byCategory = <IncidentCategory, int>{};
          for (final i in open) {
            byCategory[i.category] = (byCategory[i.category] ?? 0) + 1;
          }
          final maxCount = byCategory.values.fold<int>(1, (m, v) => v > m ? v : m);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recentIncidentsProvider),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  _Stat('New today', today, Icons.fiber_new_rounded, AppColors.primary),
                  _Stat('Open', open.length, Icons.inbox_rounded, IncidentStatus.inReview.color),
                  _Stat('In progress', inProgress, Icons.build_rounded, IncidentStatus.inProgress.color),
                  _Stat('Resolved (7 days)', resolvedWeek, Icons.check_circle_rounded, IncidentStatus.resolved.color),
                ],
              ),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: Text('Needs attention', style: Theme.of(context).textTheme.titleMedium)),
                TextButton(onPressed: onSeeAll, child: const Text('See all')),
              ]),
              if (attention.isEmpty)
                const EmptyState(icon: Icons.task_alt_rounded, title: 'Nothing waiting. Great work!')
              else
                for (final i in attention.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IncidentCard(
                      incident: i,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => IncidentDetailsScreen(incidentId: i.id))),
                    ),
                  ),
              const SizedBox(height: 16),
              Text('Open reports by category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: byCategory.isEmpty
                      ? const Text('No open reports.')
                      : Column(children: [
                          for (final e in byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(children: [
                                SizedBox(width: 90, child: Text(e.key.label, style: const TextStyle(fontSize: 13))),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: e.value / maxCount,
                                      minHeight: 12,
                                      color: e.key.color,
                                      backgroundColor: AppColors.background,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ]),
                            ),
                        ]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ]),
      );
}
