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

  Future<String> create({
    required IncidentDraft draft,
    required String uid,
    required String reporterName,
  }) async {
    final ref = _incidents.doc();
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    batch.set(ref, {
      ...draft.contentMap(),
      'status': IncidentStatus.submitted.value,
      'isAnonymous': draft.isAnonymous,
      // Anonymous reports carry no identifying fields at all.
      if (!draft.isAnonymous) 'reporterId': uid,
      if (!draft.isAnonymous) 'reporterName': reporterName,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(_owner(ref.id), {'reporterId': uid, 'reporterName': reporterName});
    batch.set(_myReport(uid, ref.id), {'createdAt': now});

    await batch.commit();
    return ref.id;
  }

  /// Owner edits while the report is still 'submitted'.
  Future<void> updateContent(String id, IncidentDraft draft) => _incidents.doc(id).update({
        ...draft.contentMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
    batch.set(_incidents.doc(id).collection('statusHistory').doc(), {
      'status': status.value,
      'note': cleanNote,
      'changedBy': staffUid,
      'changedAt': now,
    });
    await batch.commit();
  }
}
