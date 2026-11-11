import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../shared/incident_details_screen.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  IncidentStatus? _status; // null = All

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    final mine = ref.watch(myIncidentsProvider);
    final all = mine.value ?? const [];
    int count(IncidentStatus s) => all.where((i) => i.status == s).length;

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        Text('My Reports', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                child: Text((user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? '', style: Theme.of(context).textTheme.titleMedium),
                  Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _Count('Total', all.length),
          _Count('In progress', count(IncidentStatus.inProgress)),
          _Count('Resolved', count(IncidentStatus.resolved)),
        ]),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip('All', _status == null, () => setState(() => _status = null)),
            for (final s in IncidentStatus.values) _chip(s.label, _status == s, () => setState(() => _status = s)),
          ]),
        ),
        const SizedBox(height: 12),
        mine.when(
          loading: () => const ListSkeleton(count: 4),
          error: (e, _) => ErrorView(e),
          data: (list) {
            final shown = _status == null ? list : list.where((i) => i.status == _status).toList();
            if (shown.isEmpty) {
              return EmptyState(
                icon: Icons.inbox_rounded,
                title: _status == null ? 'No reports yet' : 'No ${_status!.label.toLowerCase()} reports',
                message: 'Reports you submit will appear here.',
              );
            }
            return Column(children: [
              for (final i in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IncidentCard(
                    incident: i,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => IncidentDetailsScreen(incidentId: i.id))),
                  ),
                ),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap(), showCheckmark: false),
      );
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}
