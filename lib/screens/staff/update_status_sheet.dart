import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/incident.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// Staff-only bottom sheet to move a report to a new status with a note.
class UpdateStatusSheet extends ConsumerStatefulWidget {
  const UpdateStatusSheet({super.key, required this.incident});
  final Incident incident;

  @override
  ConsumerState<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<UpdateStatusSheet> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  IncidentStatus? _status;
  bool _saving = false;

  // closing a report with zero explanation is rude. so Resolved/Rejected = note required
  // A note is required when closing a report so the student knows why.
  bool get _noteRequired => _status == IncidentStatus.resolved || _status == IncidentStatus.rejected;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_status == null) {
      showSnack(context, 'Choose a new status.', error: true);
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(incidentServiceProvider).updateStatus(
            id: widget.incident.id,
            status: _status!,
            staffUid: ref.read(authUserProvider).value!.uid,
            note: _note.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Status updated to ${_status!.label}.');
    } catch (e) {
      if (mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = IncidentStatus.values.where((s) => s != widget.incident.status && s != IncidentStatus.submitted);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Update status', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Row(children: [
                const Text('Current: '),
                StatusBadge(widget.incident.status, compact: true),
              ]),
              const SizedBox(height: 8),
              RadioGroup<IncidentStatus>(
                groupValue: _status,
                onChanged: (v) => setState(() => _status = v),
                child: Column(children: [
                  for (final s in options)
                    RadioListTile<IncidentStatus>(
                      value: s,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [
                        Icon(s.icon, color: s.color, size: 20),
                        const SizedBox(width: 8),
                        Text(s.label),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _note,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _noteRequired ? 'Note to student (required)' : 'Note to student (optional)',
                  hintText: 'e.g. Plumber assigned, expected fix by Friday',
                ),
                validator: (v) =>
                    _noteRequired && (v == null || v.trim().isEmpty) ? 'Please explain the outcome to the student' : null,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Save update'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
