import 'package:flutter/material.dart';

class AppConstants {
  static const studentDomain = '@alustudent.com';
  static const staffDomain = '@alueducation.com';

  static bool isStudentEmail(String email) => email.toLowerCase().trim().endsWith(studentDomain);
  static bool isStaffEmail(String email) => email.toLowerCase().trim().endsWith(staffDomain);

  static const locations = [
    'Block A',
    'Block B',
    'Student Residence',
    'Library',
    'Cafeteria',
    'Sports Ground',
    'Admin Building',
  ];
}

/// Incident categories (values must match firestore.rules).
enum IncidentCategory {
  facilities('Facilities', Icons.apartment_rounded, Color(0xFF0F766E)),
  water('Water', Icons.water_drop_rounded, Color(0xFF0284C7)),
  electricity('Electricity', Icons.bolt_rounded, Color(0xFFD97706)),
  sanitation('Sanitation', Icons.cleaning_services_rounded, Color(0xFF7C3AED)),
  safety('Safety', Icons.shield_rounded, Color(0xFFDC2626)),
  furniture('Furniture', Icons.chair_rounded, Color(0xFF92400E)),
  other('Other', Icons.more_horiz_rounded, Color(0xFF475569));

  const IncidentCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static IncidentCategory from(String? v) =>
      values.firstWhere((c) => c.name == v, orElse: () => IncidentCategory.other);
}

enum Urgency {
  low('Low', 'Can wait a few days'),
  medium('Medium', 'Should be fixed this week'),
  high('High', 'Affects safety or many people');

  const Urgency(this.label, this.hint);
  final String label;
  final String hint;

  static Urgency from(String? v) => values.firstWhere((u) => u.name == v, orElse: () => Urgency.medium);
}

/// Report lifecycle. Firestore stores the snake_case [value].
enum IncidentStatus {
  submitted('submitted', 'Submitted', Icons.send_rounded, Color(0xFF475569), Color(0xFFF1F5F9)),
  inReview('in_review', 'In Review', Icons.visibility_rounded, Color(0xFF7C3AED), Color(0xFFF3E8FF)),
  inProgress('in_progress', 'In Progress', Icons.build_rounded, Color(0xFFB45309), Color(0xFFFEF3C7)),
  resolved('resolved', 'Resolved', Icons.check_circle_rounded, Color(0xFF15803D), Color(0xFFDCFCE7)),
  rejected('rejected', 'Rejected', Icons.cancel_rounded, Color(0xFFB91C1C), Color(0xFFFEE2E2));

  const IncidentStatus(this.value, this.label, this.icon, this.color, this.background);
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  static IncidentStatus from(String? v) =>
      values.firstWhere((s) => s.value == v, orElse: () => IncidentStatus.submitted);

  /// Main path shown on the timeline (rejected is shown separately).
  static const timeline = [submitted, inReview, inProgress, resolved];
}
