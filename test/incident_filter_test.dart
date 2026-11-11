import 'package:flutter_test/flutter_test.dart';
import 'package:tatua/core/constants/app_constants.dart';
import 'package:tatua/models/incident.dart';
import 'package:tatua/providers/filter_provider.dart';

Incident _incident(
  String id, {
  String title = 'Report',
  IncidentCategory category = IncidentCategory.water,
  IncidentStatus status = IncidentStatus.submitted,
  Urgency urgency = Urgency.medium,
  String location = 'Block A',
  int daysAgo = 0,
}) {
  final t = DateTime(2026, 11, 10).subtract(Duration(days: daysAgo));
  return Incident(
    id: id,
    title: title,
    description: 'Some description',
    category: category,
    location: location,
    urgency: urgency,
    status: status,
    photoUrl: null,
    isAnonymous: false,
    reporterId: 'u1',
    reporterName: 'Amina',
    lastNote: null,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  final all = [
    _incident('1', title: 'Leaking tap', daysAgo: 2),
    _incident('2', title: 'Broken chair', category: IncidentCategory.furniture, location: 'Library', daysAgo: 1),
    _incident('3', title: 'Power cut', category: IncidentCategory.electricity, status: IncidentStatus.resolved, urgency: Urgency.high, daysAgo: 3),
  ];

  test('no filter returns everything, newest first', () {
    expect(const IncidentFilter().apply(all).map((i) => i.id), ['2', '1', '3']);
  });

  test('search matches title case-insensitively', () {
    expect(const IncidentFilter(query: 'TAP').apply(all).map((i) => i.id), ['1']);
  });

  test('search matches location', () {
    expect(const IncidentFilter(query: 'library').apply(all).map((i) => i.id), ['2']);
  });

  test('category filter', () {
    final f = IncidentFilter(categories: {IncidentCategory.furniture, IncidentCategory.electricity});
    expect(f.apply(all).map((i) => i.id), ['2', '3']);
  });

  test('status filter', () {
    expect(const IncidentFilter(status: IncidentStatus.resolved).apply(all).map((i) => i.id), ['3']);
  });

  test('urgency sort puts high first', () {
    expect(const IncidentFilter(sort: SortOrder.urgency).apply(all).first.id, '3');
  });

  test('activeCount counts filters but not the search text', () {
    final f = IncidentFilter(query: 'x', categories: {IncidentCategory.water}, status: IncidentStatus.submitted);
    expect(f.activeCount, 2);
  });

  test('status values match the strings used in firestore.rules', () {
    expect(IncidentStatus.values.map((s) => s.value),
        ['submitted', 'in_review', 'in_progress', 'resolved', 'rejected']);
  });
}
