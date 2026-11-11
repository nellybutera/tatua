import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/incident.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import '../staff/update_status_sheet.dart';
import '../student/report_form_screen.dart';

class IncidentDetailsScreen extends ConsumerWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId));
    final me = ref.watch(appUserProvider).value;
    final isStaff = me?.isStaff ?? false;
    final isMine = ref.watch(isMyReportProvider(incidentId));

    return incident.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: ErrorView(e)),
      data: (i) {
        if (i == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(icon: Icons.delete_outline_rounded, title: 'This report no longer exists'),
          );
        }
        final canEdit = isMine && i.status == IncidentStatus.submitted;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Incident details'),
            actions: [
              if (canEdit)
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'edit'
                      ? Navigator.push(context, MaterialPageRoute(builder: (_) => ReportFormScreen(existing: i)))
                      : _confirmDelete(context, ref, i),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Edit'))),
                    PopupMenuItem(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_rounded, color: AppColors.error), title: Text('Delete'))),
                  ],
                ),
            ],
          ),
          bottomNavigationBar: isStaff
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => UpdateStatusSheet(incident: i),
                      ),
                      icon: const Icon(Icons.sync_alt_rounded),
                      label: const Text('Update status'),
                    ),
                  ),
                )
              : null,
          body: _Body(incident: i, showReporter: isStaff || isMine),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Incident i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final uid = ref.read(authUserProvider).value!.uid;
      await ref.read(incidentServiceProvider).delete(i.id, uid);
      if (context.mounted) {
        Navigator.pop(context);
        showSnack(context, 'Report deleted.');
      }
    } catch (e) {
      if (context.mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.incident, required this.showReporter});
  final Incident incident;
  final bool showReporter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = incident;
    final text = Theme.of(context).textTheme;
    final dateFmt = DateFormat('d MMM yyyy, HH:mm');

    // Owner and staff may read the private owner record (needed for anonymous reports).
    final reporter = i.isAnonymous && showReporter
        ? ref.watch(reporterNameProvider(i.id)).value
        : null;
    final reporterLabel = i.isAnonymous
        ? (reporter != null ? '$reporter (anonymous to students)' : 'Anonymous')
        : i.displayReporter;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
      if (i.photoUrl != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              i.photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) => p == null ? child : Container(color: AppColors.primarySoft),
              errorBuilder: (_, _, _) => Container(
                color: AppColors.primarySoft,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.primary, size: 40),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        StatusBadge(i.status),
        _Pill(icon: i.category.icon, label: i.category.label, color: i.category.color),
        _Pill(
          icon: Icons.priority_high_rounded,
          label: '${i.urgency.label} urgency',
          color: i.urgency == Urgency.high ? AppColors.error : AppColors.textMuted,
        ),
      ]),
      const SizedBox(height: 12),
      Text(i.title, style: text.titleLarge),
      const SizedBox(height: 10),
      _Meta(Icons.place_outlined, i.location),
      _Meta(Icons.event_outlined, 'Submitted ${dateFmt.format(i.createdAt)}'),
      _Meta(Icons.person_outline_rounded, 'Reported by $reporterLabel'),
      _Meta(Icons.tag_rounded, 'Reference #INC-${i.id.substring(0, 6).toUpperCase()}'),
      const SizedBox(height: 18),
      Text('Status timeline', style: text.titleMedium),
      const SizedBox(height: 10),
      _Timeline(incident: i),
      const SizedBox(height: 18),
      Text('Description', style: text.titleMedium),
      const SizedBox(height: 6),
      Text(i.description, style: text.bodyMedium?.copyWith(height: 1.5)),
    ]);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13))),
        ]),
      );
}

/// Vertical timeline: Submitted -> In Review -> In Progress -> Resolved
/// (or ends in Rejected). Staff notes come from the statusHistory subcollection.
class _Timeline extends ConsumerWidget {
  const _Timeline({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider(incident.id)).value ?? const <StatusEntry>[];
    final fmt = DateFormat('d MMM, HH:mm');

    // Latest entry per status.
    final byStatus = <IncidentStatus, StatusEntry>{};
    for (final h in history) {
      byStatus[h.status] = h;
    }

    final rejected = incident.status == IncidentStatus.rejected;
    final steps = rejected
        ? [IncidentStatus.submitted, ...history.map((h) => h.status).where((s) => s != IncidentStatus.rejected).toSet(), IncidentStatus.rejected]
        : IncidentStatus.timeline;
    final currentIndex = steps.indexOf(incident.status);

    return Column(children: [
      for (var n = 0; n < steps.length; n++)
        _TimelineRow(
          status: steps[n],
          done: n <= currentIndex,
          current: n == currentIndex,
          isLast: n == steps.length - 1,
          when: steps[n] == IncidentStatus.submitted ? incident.createdAt : byStatus[steps[n]]?.changedAt,
          note: byStatus[steps[n]]?.note,
          fmt: fmt,
        ),
    ]);
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.status,
    required this.done,
    required this.current,
    required this.isLast,
    required this.when,
    required this.note,
    required this.fmt,
  });
  final IncidentStatus status;
  final bool done;
  final bool current;
  final bool isLast;
  final DateTime? when;
  final String? note;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final color = done ? status.color : AppColors.border;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: done ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: current ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)] : null,
            ),
            child: done ? Icon(status.icon, size: 14, color: Colors.white) : null,
          ),
          if (!isLast) Expanded(child: Container(width: 2, color: done ? color : AppColors.border)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 3),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(status.label,
                  style: TextStyle(
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: done ? AppColors.text : AppColors.textMuted,
                  )),
              if (done && when != null) Text(fmt.format(when!), style: Theme.of(context).textTheme.bodySmall),
              if (note != null && note!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Text(note!, style: const TextStyle(fontSize: 13)),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
