import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/filter_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'incident_details_screen.dart';

/// Browse, search and filter all campus reports.
/// Used by students ("Explore") and staff ("All Reports").
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.title = 'Explore'});
  final String title;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(incidentFilterProvider);
    final notifier = ref.read(incidentFilterProvider.notifier);
    final results = ref.watch(filteredIncidentsProvider);

    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: notifier.setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search title, description or place',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: filter.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            notifier.setQuery('');
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              child: IconButton.filledTonal(
                tooltip: 'Filters',
                style: IconButton.styleFrom(minimumSize: const Size(50, 50)),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => const FilterSheet(),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ]),
        ),
        // Active filters as removable chips
        if (filter.activeCount > 0)
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), children: [
              for (final c in filter.categories)
                _removable(c.label, () => notifier.toggleCategory(c)),
              if (filter.status != null) _removable(filter.status!.label, () => notifier.setStatus(null)),
              if (filter.location != null) _removable(filter.location!, () => notifier.setLocation(null)),
            ]),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(recentIncidentsProvider),
            child: results.when(
              loading: () => ListView(padding: const EdgeInsets.all(16), children: const [ListSkeleton(count: 5)]),
              error: (e, _) => ListView(children: [ErrorView(e)]),
              data: (list) => list.isEmpty
                  ? ListView(children: const [
                      EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching reports',
                        message: 'Try a different search or clear some filters.',
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => IncidentCard(
                        incident: list[i],
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => IncidentDetailsScreen(incidentId: list[i].id))),
                      ),
                    ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _removable(String label, VoidCallback onRemove) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InputChip(
          label: Text(label),
          onDeleted: onRemove,
          backgroundColor: AppColors.primarySoft,
          deleteIconColor: AppColors.primaryDark,
        ),
      );
}

/// Bottom sheet with category / status / location / sort options.
/// Edits a local copy and only applies it when the user taps "Apply".
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late IncidentFilter _draft = ref.read(incidentFilterProvider);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Filter reports', style: text.titleLarge),
            const SizedBox(height: 14),
            Text('Category', style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in IncidentCategory.values)
                FilterChip(
                  avatar: Icon(c.icon, size: 16, color: c.color),
                  label: Text(c.label),
                  selected: _draft.categories.contains(c),
                  onSelected: (_) => setState(() {
                    final next = {..._draft.categories};
                    next.contains(c) ? next.remove(c) : next.add(c);
                    _draft = _draft.copyWith(categories: next);
                  }),
                ),
            ]),
            const SizedBox(height: 16),
            Text('Status', style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(
                label: const Text('Any'),
                selected: _draft.status == null,
                onSelected: (_) => setState(() => _draft = _draft.copyWith(status: () => null)),
              ),
              for (final s in IncidentStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _draft.status == s,
                  onSelected: (_) => setState(() => _draft = _draft.copyWith(status: () => s)),
                ),
            ]),
            const SizedBox(height: 16),
            Text('Location', style: text.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _draft.location,
              items: [
                const DropdownMenuItem(value: null, child: Text('Anywhere')),
                for (final l in AppConstants.locations) DropdownMenuItem(value: l, child: Text(l)),
              ],
              onChanged: (v) => setState(() => _draft = _draft.copyWith(location: () => v)),
            ),
            const SizedBox(height: 16),
            Text('Sort by', style: text.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<SortOrder>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: SortOrder.newest, label: Text('Newest')),
                ButtonSegment(value: SortOrder.oldest, label: Text('Oldest')),
                ButtonSegment(value: SortOrder.urgency, label: Text('Urgency')),
              ],
              selected: {_draft.sort},
              onSelectionChanged: (s) => setState(() => _draft = _draft.copyWith(sort: s.first)),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(incidentFilterProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final current = ref.read(incidentFilterProvider);
                    ref.read(incidentFilterProvider.notifier).replace(_draft.copyWith(query: current.query));
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
