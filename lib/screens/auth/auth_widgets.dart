import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared scaffold for the sign up / log in / reset screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            child,
          ]),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, this.validator, this.hint, this.onChanged});
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      validator: widget.validator,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint ?? '••••••••',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Show password' : 'Hide password',
          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

/// 0..4 score used for the strength bar on sign up.
int passwordScore(String p) {
  var s = 0;
  if (p.length >= 8) s++;
  if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
  if (RegExp(r'\d').hasMatch(p)) s++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
  return s;
}

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar(this.password, {super.key});
  final String password;

  @override
  Widget build(BuildContext context) {
    final score = passwordScore(password);
    const labels = ['Too weak', 'Weak', 'Fair', 'Good', 'Strong'];
    const colors = [AppColors.error, AppColors.error, AppColors.accent, AppColors.primary, AppColors.primary];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: i < score ? colors[score] : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        const SizedBox(width: 6),
        Text(password.isEmpty ? '' : labels[score], style: TextStyle(fontSize: 12, color: colors[score])),
      ]),
    );
  }
}
