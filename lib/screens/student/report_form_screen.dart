import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/incident.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/common.dart';
import 'report_success_screen.dart';

/// Create a new report, or edit one (pass [existing]) while it is still "submitted".
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.existing});
  final Incident? existing;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  static const _sep = ' – ';

  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _room = TextEditingController();

  IncidentCategory? _category;
  String? _building;
  Urgency _urgency = Urgency.medium;
  bool _anonymous = false;
  File? _photo; // newly picked photo
  String? _existingPhotoUrl; // photo already on Cloudinary (edit mode)
  bool _saving = false;
  String? _progressText;
  bool _triedSubmit = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description;
      _category = e.category;
      _urgency = e.urgency;
      _anonymous = e.isAnonymous;
      _existingPhotoUrl = e.photoUrl;
      final parts = e.location.split(_sep);
      _building = AppConstants.locations.contains(parts.first) ? parts.first : null;
      if (parts.length > 1) _room.text = parts.sublist(1).join(_sep);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      // Compress on the device: smaller uploads, faster for students on mobile data.
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 1280);
      if (picked != null) setState(() => _photo = File(picked.path));
    } catch (_) {
      if (mounted) showSnack(context, 'Could not open the camera or gallery. Check app permissions.', error: true);
    }
  }

  String get _location {
    final room = _room.text.trim();
    return room.isEmpty ? _building! : '$_building$_sep$room';
  }

  Future<void> _submit() async {
    setState(() => _triedSubmit = true);
    final validForm = _form.currentState!.validate();
    if (!validForm || _category == null || _building == null) {
      showSnack(context, 'Please fill in the highlighted fields.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      String? photoUrl = _existingPhotoUrl;
      if (_photo != null) {
        setState(() => _progressText = 'Uploading photo…');
        photoUrl = await ref.read(cloudinaryServiceProvider).uploadImage(_photo!);
      }
      setState(() => _progressText = _isEdit ? 'Saving changes…' : 'Submitting report…');

      final draft = IncidentDraft(
        title: _title.text,
        description: _description.text,
        category: _category!,
        location: _location,
        urgency: _urgency,
        isAnonymous: _anonymous,
        photoUrl: photoUrl,
      );

      final service = ref.read(incidentServiceProvider);
      if (_isEdit) {
        await service.updateContent(widget.existing!.id, draft);
        if (!mounted) return;
        showSnack(context, 'Report updated.');
        Navigator.pop(context);
      } else {
        final user = ref.read(appUserProvider).value!;
        final id = await service.create(draft: draft, uid: user.uid, reporterName: user.name);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReportSuccessScreen(incidentId: id)));
      }
    } on CloudinaryException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progressText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit report' : 'Report an issue')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)),
                    const SizedBox(width: 10),
                    Text(_progressText ?? 'Please wait…'),
                  ])
                : Text(_isEdit ? 'Save changes' : 'Submit report'),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
          // Category
          Text('Select a category', style: text.titleMedium),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: [
              for (final c in IncidentCategory.values)
                _CategoryTile(category: c, selected: _category == c, onTap: () => setState(() => _category = c)),
            ],
          ),
          if (_triedSubmit && _category == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Please choose a category', style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),

          // Title
          const _Label('Title'),
          TextFormField(
            controller: _title,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. No water in Block B toilets'),
            validator: (v) => (v == null || v.trim().length < 3) ? 'Please add a short title (3+ characters)' : null,
          ),

          // Description
          const _Label('Description'),
          TextFormField(
            controller: _description,
            maxLength: 500,
            minLines: 4,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'What happened? When did you notice it? Who is affected?'),
            validator: (v) => (v == null || v.trim().length < 10) ? 'Please describe the issue (10+ characters)' : null,
          ),

          // Location
          const _Label('Location'),
          DropdownButtonFormField<String>(
            initialValue: _building,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.place_outlined), hintText: 'Choose a building'),
            items: [for (final l in AppConstants.locations) DropdownMenuItem(value: l, child: Text(l))],
            onChanged: (v) => setState(() => _building = v),
            validator: (v) => v == null ? 'Please choose a location' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _room,
            maxLength: 50,
            decoration: const InputDecoration(hintText: 'Room / exact spot (optional), e.g. Room 204'),
          ),

          // Urgency
          const _Label('Urgency'),
          SegmentedButton<Urgency>(
            segments: [for (final u in Urgency.values) ButtonSegment(value: u, label: Text(u.label))],
            selected: {_urgency},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _urgency = s.first),
          ),
          const SizedBox(height: 6),
          Text(_urgency.hint, style: text.bodySmall),

          // Photo
          const _Label('Add a photo (optional)'),
          _PhotoBox(
            file: _photo,
            url: _existingPhotoUrl,
            onPick: _saving ? null : _pickPhoto,
            onRemove: _saving
                ? null
                : () => setState(() {
                      _photo = null;
                      _existingPhotoUrl = null;
                    }),
          ),

          // Anonymous
          if (!_isEdit) ...[
            const SizedBox(height: 14),
            Card(
              child: SwitchListTile(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
                title: const Text('Report anonymously', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Your name is hidden from other students. Staff can still see who reported it.'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected, required this.onTap});
  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: category.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(category.icon, color: selected ? Colors.white : category.color),
            const SizedBox(height: 6),
            Text(category.label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.text)),
          ]),
        ),
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.file, required this.url, required this.onPick, required this.onRemove});
  final File? file;
  final String? url;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = file != null || url != null;
    if (!hasPhoto) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.4),
          ),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 30),
            SizedBox(height: 6),
            Text('Tap to add a photo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            Text('JPG or PNG, up to 5 MB', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
      );
    }
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: file != null
            ? Image.file(file!, height: 180, width: double.infinity, fit: BoxFit.cover)
            : Image.network(url!, height: 180, width: double.infinity, fit: BoxFit.cover),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: IconButton.filled(
          tooltip: 'Remove photo',
          style: IconButton.styleFrom(backgroundColor: Colors.black54),
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ),
      Positioned(
        bottom: 8,
        right: 8,
        child: FilledButton.tonalIcon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
          onPressed: onPick,
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Change'),
        ),
      ),
    ]);
  }
}
