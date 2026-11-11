import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final Urgency urgency;
  final IncidentStatus status;
  final String? photoUrl;
  final bool isAnonymous;
  final String? reporterId; // null when anonymous
  final String? reporterName; // null when anonymous
  final String? lastNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.urgency,
    required this.status,
    required this.photoUrl,
    required this.isAnonymous,
    required this.reporterId,
    required this.reporterName,
    required this.lastNote,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayReporter => isAnonymous ? 'Anonymous' : (reporterName ?? 'Student');

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    // Server timestamps are null for a moment on the device that wrote them.
    final created = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Incident(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: IncidentCategory.from(d['category'] as String?),
      location: d['location'] as String? ?? '',
      urgency: Urgency.from(d['urgency'] as String?),
      status: IncidentStatus.from(d['status'] as String?),
      photoUrl: d['photoUrl'] as String?,
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      reporterId: d['reporterId'] as String?,
      reporterName: d['reporterName'] as String?,
      lastNote: d['lastNote'] as String?,
      createdAt: created,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? created,
    );
  }
}

/// Fields a student fills in on the report form.
class IncidentDraft {
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final Urgency urgency;
  final bool isAnonymous;
  final String? photoUrl;

  const IncidentDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.urgency,
    required this.isAnonymous,
    this.photoUrl,
  });

  Map<String, dynamic> contentMap() => {
        'title': title.trim(),
        'description': description.trim(),
        'category': category.name,
        'location': location.trim(),
        'urgency': urgency.name,
        'photoUrl': photoUrl,
      };
}

class StatusEntry {
  final String id;
  final IncidentStatus status;
  final String? note;
  final DateTime changedAt;

  const StatusEntry({required this.id, required this.status, this.note, required this.changedAt});

  factory StatusEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return StatusEntry(
      id: doc.id,
      status: IncidentStatus.from(d['status'] as String?),
      note: d['note'] as String?,
      changedAt: (d['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
