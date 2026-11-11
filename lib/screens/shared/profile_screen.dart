import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String uid, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.trim().length < 2) return;
    try {
      await ref.read(authServiceProvider).updateName(uid, name);
      if (context.mounted) showSnack(context, 'Name updated.');
    } catch (e) {
      if (context.mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primarySoft,
            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 12),
        Text(user.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        Text(user.email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: user.isStaff ? AppColors.accent.withValues(alpha: 0.15) : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(user.isStaff ? 'Staff' : 'Student',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: user.isStaff ? const Color(0xFFB66A05) : AppColors.primaryDark,
                )),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Edit name'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _editName(context, ref, user.uid, user.name),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.location_city_outlined),
              title: Text('Campus'),
              trailing: Text('ALU Kigali'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Your privacy'),
                  content: const Text(
                      'Reports are visible to ALU students and staff. If you report anonymously, other students '
                      'cannot see who you are; only staff can, so they can follow up. Photos are stored on '
                      'Cloudinary and only linked from your report.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () => _logout(context, ref),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out'),
        ),
      ]),
    );
  }
}
