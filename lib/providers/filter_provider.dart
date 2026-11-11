import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/incident.dart';
import 'providers.dart';

enum SortOrder { newest, oldest, urgency }

/// Search + filter settings for the Explore / All Reports screen.
class IncidentFilter {
  final String query;
  final Set<IncidentCategory> categories;
  final IncidentStatus? status;
  final String? location;
  final SortOrder sort;

  const IncidentFilter({
    this.query = '',
    this.categories = const {},
    this.status,
    this.location,
    this.sort = SortOrder.newest,
  });

  int get activeCount => categories.length + (status != null ? 1 : 0) + (location != null ? 1 : 0);

  IncidentFilter copyWith({
    String? query,
    Set<IncidentCategory>? categories,
    IncidentStatus? Function()? status,
    String? Function()? location,
    SortOrder? sort,
  }) =>
      IncidentFilter(
        query: query ?? this.query,
        categories: categories ?? this.categories,
        status: status != null ? status() : this.status,
        location: location != null ? location() : this.location,
        sort: sort ?? this.sort,
      );

  /// Pure function so it is easy to unit test.
  List<Incident> apply(List<Incident> all) {
    final q = query.trim().toLowerCase();
    final result = all.where((i) {
      if (q.isNotEmpty &&
          !i.title.toLowerCase().contains(q) &&
          !i.description.toLowerCase().contains(q) &&
          !i.location.toLowerCase().contains(q)) {
        return false;
      }
      if (categories.isNotEmpty && !categories.contains(i.category)) return false;
      if (status != null && i.status != status) return false;
      if (location != null && !i.location.startsWith(location!)) return false;
      return true;
    }).toList();

    switch (sort) {
      case SortOrder.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOrder.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOrder.urgency:
        result.sort((a, b) {
          final u = b.urgency.index.compareTo(a.urgency.index);
          return u != 0 ? u : b.createdAt.compareTo(a.createdAt);
        });
    }
    return result;
  }
}

class IncidentFilterNotifier extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() {
    // Start fresh whenever a different user signs in, so one account's
    // search/filters never carry over to the next.
    ref.watch(authUserProvider.select((u) => u.value?.uid));
    return const IncidentFilter();
  }

  void setQuery(String q) => state = state.copyWith(query: q);
  void setStatus(IncidentStatus? s) => state = state.copyWith(status: () => s);
  void setLocation(String? l) => state = state.copyWith(location: () => l);
  void setSort(SortOrder s) => state = state.copyWith(sort: s);
  void toggleCategory(IncidentCategory c) {
    final next = {...state.categories};
    next.contains(c) ? next.remove(c) : next.add(c);
    state = state.copyWith(categories: next);
  }

  void replace(IncidentFilter f) => state = f;
  void reset() => state = IncidentFilter(query: state.query);
}

final incidentFilterProvider =
    NotifierProvider<IncidentFilterNotifier, IncidentFilter>(IncidentFilterNotifier.new);

/// Recent incidents with the current search/filter applied.
final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  return ref.watch(recentIncidentsProvider).whenData(filter.apply);
});
