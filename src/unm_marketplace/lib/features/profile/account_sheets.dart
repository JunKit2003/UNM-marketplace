import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/api/models.dart';
import '../../state/auth.dart';
import '../../state/providers.dart';

Future<void> _sheet(BuildContext context, Widget child) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
  builder: (c) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      0,
      24,
      24 + MediaQuery.viewInsetsOf(c).bottom,
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: child,
    ),
  ),
);

Future<void> showEditProfileSheet(
  BuildContext context,
  WidgetRef ref,
  User user,
) => _sheet(context, _EditProfile(user: user));

Future<void> showChangePasswordSheet(BuildContext context, WidgetRef ref) =>
    _sheet(context, const _ChangePassword());

class _EditProfile extends ConsumerStatefulWidget {
  const _EditProfile({required this.user});
  final User user;

  @override
  ConsumerState<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<_EditProfile> {
  late final _first = TextEditingController(text: widget.user.firstName);
  late final _last = TextEditingController(text: widget.user.lastName);
  late final _phone = TextEditingController(text: widget.user.phone);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final u = await ref
          .read(authRepositoryProvider)
          .updateProfile(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            phone: _phone.text.trim(),
          );
      ref.read(authProvider.notifier).updated(u);
      if (mounted) Navigator.pop(context);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Edit profile', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 20),
      TextField(
        controller: _first,
        decoration: const InputDecoration(labelText: 'First name'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _last,
        decoration: const InputDecoration(labelText: 'Last name'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Phone'),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 20),
      FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
    ],
  );
}

class _ChangePassword extends ConsumerStatefulWidget {
  const _ChangePassword();

  @override
  ConsumerState<_ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends ConsumerState<_ChangePassword> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  Map<String, String> _fields = {};
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text.length < 8) {
      return setState(
        () => _fields = {'newPassword': 'Use at least 8 characters.'},
      );
    }
    setState(() {
      _busy = true;
      _fields = {};
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(_current.text, _next.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password changed')));
    } on ApiError catch (e) {
      setState(() {
        _fields = e.fields;
        _error = e.fields.isEmpty ? e.message : null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Change password', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 20),
      TextField(
        controller: _current,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Current password',
          errorText: _fields['currentPassword'],
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _next,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'New password',
          errorText: _fields['newPassword'],
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: const Text('Change password'),
      ),
    ],
  );
}
