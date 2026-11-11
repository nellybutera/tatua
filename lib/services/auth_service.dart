import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';

/// Wraps Firebase Authentication and the users/{uid} profile document.
class AuthService {
  AuthService(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> userChanges() => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  // sign up in 4 moves:
  //   1. not an @alustudent.com email? bye, we don't even bother Firebase
  //   2. make the account
  //   3. save their name
  //   4. fire off the verification email (you're stuck on "verify email" till you click it)
  Future<void> signUp({required String name, required String email, required String password}) async {
    if (!AppConstants.isStudentEmail(email)) {
      throw FirebaseAuthException(code: 'not-alu-email');
    }
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user!.updateDisplayName(name.trim());
    await cred.user!.sendEmailVerification();
  }

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerification() async => _auth.currentUser?.sendEmailVerification();

  // this runs when you tap "I've verified my email"
  // heads up: this one bit me. reload() first = Firestore still thinks you're unverified.
  // so it's token FIRST, then reload. order matters here.
  /// Reloads the user and refreshes the ID token so Firestore rules see
  /// email_verified = true straight after the user clicks the link.
  Future<bool> refreshVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Refresh the token FIRST: reload() notifies listeners (AuthGate) immediately,
    // and their Firestore calls must already carry email_verified = true.
    await user.getIdToken(true);
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Creates the student profile the first time a verified student signs in.
  /// (Rules only allow this once the email is verified.)
  // role is ALWAYS 'student' here. there's literally no code that makes someone staff,
  // that only happens by hand in the Firebase console
  Future<void> ensureStudentProfile(User user) async {
    await user.getIdToken(true); // make sure the rules see the verified email
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'name': (user.displayName?.trim().isNotEmpty ?? false) ? user.displayName!.trim() : 'Student',
      'email': user.email,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateName(String uid, String name) async {
    await _db.collection('users').doc(uid).update({'name': name.trim()});
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  Future<void> signOut() => _auth.signOut();

  /// Turns Firebase error codes into messages a student can act on.
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'not-alu-email':
          return 'Please use your ALU email (${AppConstants.studentDomain}).';
        case 'email-already-in-use':
          return 'An account already exists for this email. Try logging in.';
        case 'invalid-email':
          return 'That email address does not look right.';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'No internet connection. Check your network and try again.';
      }
      return e.message ?? 'Something went wrong. Please try again.';
    }
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'You do not have permission to do that.';
    }
    return 'Something went wrong. Please try again.';
  }
}
