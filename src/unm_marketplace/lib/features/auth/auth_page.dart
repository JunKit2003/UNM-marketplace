import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/repositories/auth_repository.dart';
import '../../state/auth.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_mesh.dart';

/// Log in / Sign up on a frosted card over the gradient, with the one-click demo.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.from});
  final String? from;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _signup = false;
  bool _busy = false;
  String? _error;
  Map<String, String> _fields = {};
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();
  final _c = {
    for (final k in ['email', 'password', 'firstName', 'lastName', 'username', 'phone', 'signupEmail', 'signupPassword'])
      k: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _target {
    final f = widget.from;
    return (f != null && f.startsWith('/') && !f.startsWith('//')) ? f : '/';
  }

  Future<void> _run(Future<void> Function() op) async {
    setState(() {
      _busy = true;
      _error = null;
      _fields = {};
    });
    try {
      await op();
      if (mounted) context.go(_target);
    } on ApiError catch (e) {
      setState(() {
        _fields = e.fields;
        _error = e.fields.isEmpty ? e.message : null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _login() {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    _run(() => ref.read(authProvider.notifier).login(_c['email']!.text.trim(), _c['password']!.text));
  }

  void _register() {
    if (!(_signupKey.currentState?.validate() ?? false)) return;
    _run(() => ref.read(authProvider.notifier).signup(SignupData(
          firstName: _c['firstName']!.text.trim(),
          lastName: _c['lastName']!.text.trim(),
          username: _c['username']!.text.trim(),
          email: _c['signupEmail']!.text.trim(),
          phone: _c['phone']!.text.trim(),
          password: _c['signupPassword']!.text,
        )));
  }

  /// [ctl] names the controller in [_c]; [apiField] is the API's field name for server errors.
  Widget _field(String key, String label,
      {required String ctl, String? apiField, bool obscure = false, TextInputType? type, String? Function(String?)? validator, Iterable<String>? autofill}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        key: Key(key),
        controller: _c[ctl],
        obscureText: obscure,
        keyboardType: type,
        autofillHints: autofill,
        validator: validator,
        decoration: InputDecoration(labelText: label, errorText: _fields[apiField ?? ctl], errorMaxLines: 2),
        onFieldSubmitted: (_) => _signup ? _register() : _login(),
      ),
    );
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Required.' : null;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final loginForm = Form(
      key: _loginKey,
      child: AutofillGroup(
        child: Column(children: [
          _field('login-email', 'Email', ctl: 'email', type: TextInputType.emailAddress, validator: _required, autofill: const [AutofillHints.email]),
          _field('login-password', 'Password', ctl: 'password', obscure: true, validator: _required, autofill: const [AutofillHints.password]),
          _Submit(key: const Key('login-submit'), label: 'Log in', busy: _busy, onPressed: _login),
        ]),
      ),
    );
    final signupForm = Form(
      key: _signupKey,
      child: AutofillGroup(
        child: Column(children: [
          Row(children: [
            Expanded(child: _field('signup-firstName', 'First name', ctl: 'firstName', validator: _required, autofill: const [AutofillHints.givenName])),
            const SizedBox(width: 12),
            Expanded(child: _field('signup-lastName', 'Last name', ctl: 'lastName', autofill: const [AutofillHints.familyName])),
          ]),
          _field('signup-username', 'Username', ctl: 'username', validator: _required, autofill: const [AutofillHints.newUsername]),
          _field('signup-email', 'Email', ctl: 'signupEmail', apiField: 'email', type: TextInputType.emailAddress, validator: _required, autofill: const [AutofillHints.email]),
          _field('signup-phone', 'Phone (optional)', ctl: 'phone', type: TextInputType.phone, autofill: const [AutofillHints.telephoneNumber]),
          _field('signup-password', 'Password', ctl: 'signupPassword', apiField: 'password', obscure: true, autofill: const [AutofillHints.newPassword],
              validator: (v) => (v ?? '').length < 8 ? 'Use at least 8 characters.' : null),
          _Submit(key: const Key('signup-submit'), label: 'Create account', busy: _busy, onPressed: _register),
        ]),
      ),
    );

    return Scaffold(
      body: GradientMesh(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(children: [
                  InkWell(onTap: () => context.go('/'), child: const BrandMark(size: 56)),
                  const SizedBox(height: 18),
                  Text(_signup ? 'Join the campus market' : 'Welcome back', style: t.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Nott-A-Marketplace', style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  GlassPanel(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Log in')),
                          ButtonSegment(value: true, label: Text('Sign up')),
                        ],
                        selected: {_signup},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() {
                          _signup = s.first;
                          _error = null;
                          _fields = {};
                        }),
                      ),
                      const SizedBox(height: 22),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _signup ? signupForm : loginForm,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 18),
                      const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or')), Expanded(child: Divider())]),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => _run(() => ref.read(authProvider.notifier).demo()),
                        icon: const Icon(Icons.bolt_rounded, color: AppTokens.cyan),
                        label: const Text('Try the demo'),
                      ),
                      const SizedBox(height: 8),
                      Text('No sign-up needed. You get a guest account that resets nightly.',
                          textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ]),
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Submit extends StatelessWidget {
  const _Submit({super.key, required this.label, required this.busy, required this.onPressed});
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          child: busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
        ),
      );
}
