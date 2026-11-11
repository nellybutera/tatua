import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/incident.dart';

/// Small rounded logo mark + wordmark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 36, this.showName = true});
  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(Icons.handyman_rounded, color: Colors.white, size: size * 0.55),
      ),
      if (showName) ...[
        const SizedBox(width: 10),
        Text('Tatua', style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ],
    ]);
  }
}

/// Status pill: always icon + label (never colour alone, for accessibility).
// status = icon + word, never just a color. colorblind folks need to read it too
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.compact = false});
  final IncidentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: ${status.label}',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
        decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(status.icon, size: compact ? 12 : 14, color: status.color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w600, color: status.color)),
        ]),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {super.key, this.size = 48});
  final IncidentCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(category.icon, color: category.color, size: size * 0.5),
    );
  }
}

/// Photo thumbnail if there is one, otherwise the category icon.
class IncidentThumb extends StatelessWidget {
  const IncidentThumb(this.incident, {super.key, this.size = 56});
  final Incident incident;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (incident.photoUrl == null) return CategoryIcon(incident.category, size: size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        incident.photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CategoryIcon(incident.category, size: size),
      ),
    );
  }
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  if (d.inDays < 7) return '${d.inDays} d ago';
  return DateFormat('d MMM yyyy').format(t);
}

// the report card you see in every list. high urgency + still open = red border, can't miss it
class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});
  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final high = incident.urgency == Urgency.high &&
        incident.status != IncidentStatus.resolved &&
        incident.status != IncidentStatus.rejected;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: high
              ? const BoxDecoration(border: Border(left: BorderSide(color: AppColors.error, width: 4)))
              : null,
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            IncidentThumb(incident),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(incident.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(incident.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(timeAgo(incident.createdAt), style: Theme.of(context).textTheme.bodySmall),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            StatusBadge(incident.status, compact: true),
          ]),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message});
  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: Icon(icon, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}

/// Grey placeholder list shown while data loads.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: const Color(0xFFEFF3F6), borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {super.key});
  final Object error;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load data',
        message: error.toString().contains('permission-denied')
            ? 'You do not have permission to view this.'
            : 'Check your connection and try again.',
      );
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : null,
    ));
}
