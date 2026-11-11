import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/incident_service.dart';

// ok so here's how the state management works (Riverpod)
// screens never talk to Firebase directly. they just "watch" these providers.
//   Provider        -> holds one thing, like a service
//   StreamProvider  -> LIVE Firestore data. it changes, the screen redraws itself
//   .family         -> same provider but you hand it something, like an incident id
// providers can watch each other, so it's a chain:
//   who's logged in -> their profile -> their report ids -> their actual reports
// the layers: Screens -> Providers -> Services -> Firebase / Cloudinary

// ---------- services (single instances, easy to swap for fakes in tests) ----------
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)),
);
final incidentServiceProvider = Provider<IncidentService>(
  (ref) => IncidentService(ref.watch(firestoreProvider)),
);
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());

// ---------- auth state ----------
/// Emits on sign in/out AND when the user object changes (e.g. after verification reload).
final authUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).userChanges(),
);

/// The signed-in user's Firestore profile (null until created).
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);
});

// ---------- incidents ----------
final recentIncidentsProvider = StreamProvider<List<Incident>>(
  (ref) => ref.watch(incidentServiceProvider).watchRecent(),
);

// why a list of ids and not just "where reporterId == me"?
// cuz anonymous reports don't HAVE a reporterId, that search would miss them.
// so everyone keeps their own private little list instead
final myReportIdsProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(incidentServiceProvider).watchMyReportIds(uid);
});

/// Re-subscribes automatically whenever the list of my report ids changes.
final myIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final ids = ref.watch(myReportIdsProvider).value ?? const <String>[];
  return ref.watch(incidentServiceProvider).watchByIds(ids);
});

final incidentProvider = StreamProvider.family<Incident?, String>(
  (ref, id) => ref.watch(incidentServiceProvider).watchIncident(id),
);

final historyProvider = StreamProvider.family<List<StatusEntry>, String>(
  (ref, id) => ref.watch(incidentServiceProvider).watchHistory(id),
);

/// Reporter name from the private owner doc (owner + staff only).
final reporterNameProvider = FutureProvider.family<String?, String>(
  (ref, id) => ref.watch(incidentServiceProvider).reporterName(id),
);

/// Whether the current user owns a report (works for anonymous reports too).
// is this report mine? that decides if you see Edit/Delete
final isMyReportProvider = Provider.family<bool, String>((ref, id) {
  final ids = ref.watch(myReportIdsProvider).value ?? const <String>[];
  return ids.contains(id);
});
