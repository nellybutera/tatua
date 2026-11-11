import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      // AuthGate now shows the "verify your email" screen.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Use your ALU student email so we know you are part of campus.',
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const FieldLabel('Full name'),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Amina Hassan', prefixIcon: Icon(Icons.person_outline_rounded)),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your name' : null,
          ),
          const FieldLabel('ALU email'),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'name${AppConstants.studentDomain}',
              helperText: 'Use your ${AppConstants.studentDomain} email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) {
              final email = v?.trim() ?? '';
              if (email.isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter a valid email';
              if (!AppConstants.isStudentEmail(email)) return 'Please use your ALU email address';
              return null;
            },
          ),
          const FieldLabel('Password'),
          PasswordField(
            controller: _password,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.length < 8) return 'Use at least 8 characters';
              if (passwordScore(v) < 2) return 'Add numbers or capital letters';
              return null;
            },
          ),
          PasswordStrengthBar(_password.text),
          const FieldLabel('Confirm password'),
          PasswordField(
            controller: _confirm,
            validator: (v) => v != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Create account'),
          ),
        ]),
      ),
    );
  }
}
