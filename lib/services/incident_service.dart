import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/incident.dart';

/// All Firestore reads/writes for incident reports.
///
/// Writes that touch several documents use a batch so they succeed or fail
/// together (the security rules also check them together with getAfter()).
class IncidentService {
  IncidentService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents => _db.collection('incidents');

  DocumentReference<Map<String, dynamic>> _owner(String id) =>
      _incidents.doc(id).collection('private').doc('owner');

  DocumentReference<Map<String, dynamic>> _myReport(String uid, String id) =>
      _db.collection('users').doc(uid).collection('myReports').doc(id);

  /// Latest reports across campus (newest first).
  Stream<List<Incident>> watchRecent({int limit = 50}) => _incidents
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Incident.fromDoc).toList());

  Stream<Incident?> watchIncident(String id) =>
      _incidents.doc(id).snapshots().map((d) => d.exists ? Incident.fromDoc(d) : null);

  Stream<List<StatusEntry>> watchHistory(String id) => _incidents
      .doc(id)
      .collection('statusHistory')
      .orderBy('changedAt')
      .snapshots()
      .map((s) => s.docs.map(StatusEntry.fromDoc).toList());

  /// IDs of the current user's own reports (includes anonymous ones).
  Stream<List<String>> watchMyReportIds(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('myReports')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList());

  /// Loads up to 30 incidents by id (Firestore 'whereIn' limit).
  Stream<List<Incident>> watchByIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value(const []);
    return _incidents
        .where(FieldPath.documentId, whereIn: ids.take(30).toList())
        .snapshots()
        .map((s) {
      final list = s.docs.map(Incident.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Who filed a report. Only the owner and staff are allowed to read this.
  Future<String?> reporterName(String id) async {
    final snap = await _owner(id).get();
    return snap.data()?['reporterName'] as String?;
  }

  // creating a report = ONE batch, THREE docs, all or nothing:
  //   1. incidents/{id}                 the public report everyone sees
  //   2. incidents/{id}/private/owner   who actually sent it (only you + staff can peek)
  //   3. users/{me}/myReports/{id}      your own list, so even anonymous ones show in My Reports
  // if the app dies halfway, nothing gets saved. no orphan reports floating around
  Future<String> create({
    required IncidentDraft draft,
    required String uid,
    required String reporterName,
  }) async {
    final ref = _incidents.doc();
    // time comes from Google's server, not the phone, so nobody can fake the date
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    batch.set(ref, {
      ...draft.contentMap(),
      'status': IncidentStatus.submitted.value,
      'isAnonymous': draft.isAnonymous,
      // anonymous? then your name and id just... aren't on here. at all.
      // Anonymous reports carry no identifying fields at all.
      if (!draft.isAnonymous) 'reporterId': uid,
      if (!draft.isAnonymous) 'reporterName': reporterName,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(_owner(ref.id), {'reporterId': uid, 'reporterName': reporterName});
    batch.set(_myReport(uid, ref.id), {'createdAt': now});

    await batch.commit(); // send all 3 in one go
    return ref.id;
  }

  /// Owner edits while the report is still 'submitted'.
  Future<void> updateContent(String id, IncidentDraft draft) => _incidents.doc(id).update({
        ...draft.contentMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // delete is a batch too, so we don't leave junk owner/myReports docs behind
  Future<void> delete(String id, String uid) async {
    final batch = _db.batch()
      ..delete(_incidents.doc(id))
      ..delete(_owner(id))
      ..delete(_myReport(uid, id));
    await batch.commit();
  }

  /// Staff only: change status and add a timeline entry in one batch.
  Future<void> updateStatus({
    required String id,
    required IncidentStatus status,
    required String staffUid,
    String? note,
  }) async {
    final cleanNote = (note == null || note.trim().isEmpty) ? null : note.trim();
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.update(_incidents.doc(id), {
      'status': status.value,
      'lastNote': cleanNote ?? FieldValue.delete(),
      'updatedAt': now,
    });
    // every status change drops a history entry. that's literally what draws
    // the timeline on the details screen (who changed it, when, and the note)
    batch.set(_incidents.doc(id).collection('statusHistory').doc(), {
      'status': status.value,
      'note': cleanNote,
      'changedBy': staffUid,
      'changedAt': now,
    });
    await batch.commit();
  }
}
