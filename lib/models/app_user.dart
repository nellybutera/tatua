import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'student' | 'staff'
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  bool get isStaff => role == 'staff';
  String get firstName => name.trim().split(' ').first;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: (d['name'] as String?) ?? 'Student',
      email: (d['email'] as String?) ?? '',
      role: (d['role'] as String?) ?? 'student',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
