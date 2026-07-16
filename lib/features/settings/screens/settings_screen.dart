import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../entries/providers/entries_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isGoogleUser(User user) =>
      user.providerData.any((p) => p.providerId == 'google.com');

  Future<void> _editName(User user) async {
    final controller = TextEditingController(text: user.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(newName);
      if (mounted) setState(() {});
      _snack('Name updated.');
    } catch (e) {
      _snack(authErrorMessage(e));
    }
  }

  Future<void> _chooseTheme() async {
    final current = ref.read(themeModeProvider);
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appearance'),
        content: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (v) => Navigator.pop(ctx, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                value: mode,
                title: Text(themeModeLabel(mode)),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      await ref.read(themeModeProvider.notifier).set(selected);
    }
  }

  Future<void> _changePassword(String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Text(
          'We\'ll email a password-reset link to $email. '
          'Open it to set a new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      _snack('Password-reset email sent to $email.');
    } catch (e) {
      _snack(authErrorMessage(e));
    }
  }

  Future<void> _confirmSignOut() async {
    if (await confirmSignOut(context)) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.read(authRepositoryProvider).currentUser;
    final themeMode = ref.watch(themeModeProvider);
    final entryCount =
        ref.watch(entriesStreamProvider).valueOrNull?.length ?? 0;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final isGoogle = _isGoogleUser(user);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _ProfileCard(user: user, isGoogle: isGoogle, onEditName: _editName),
          const SizedBox(height: 24),
          _SectionLabel('Appearance'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Theme'),
              subtitle: Text(themeModeLabel(themeMode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _chooseTheme,
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Account'),
          Card(
            child: Column(
              children: [
                if (!isGoogle)
                  ListTile(
                    leading: const Icon(Icons.lock_reset_outlined),
                    title: const Text('Change password'),
                    subtitle: const Text('Sends a reset link to your email'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _changePassword(user.email ?? ''),
                  ),
                if (!isGoogle) const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text('Sign out',
                      style: TextStyle(color: theme.colorScheme.error)),
                  onTap: _confirmSignOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: const Text('Total entries'),
                  trailing:
                      Text('$entryCount', style: theme.textTheme.titleMedium),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.isGoogle,
    required this.onEditName,
  });

  final User user;
  final bool isGoogle;
  final Future<void> Function(User) onEditName;

  String get _initials {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      final letters = parts.take(2).map((p) => p[0]).join();
      return letters.toUpperCase();
    }
    final email = user.email ?? '?';
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = user.photoURL;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage:
                  (photoUrl != null) ? NetworkImage(photoUrl) : null,
              child: (photoUrl == null)
                  ? Text(
                      _initials,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    user.displayName?.trim().isNotEmpty == true
                        ? user.displayName!.trim()
                        : 'No name set',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit name',
                  onPressed: () => onEditName(user),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              user.email ?? '—',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _InfoChip(
                  icon: isGoogle ? Icons.g_mobiledata : Icons.email_outlined,
                  label: isGoogle ? 'Google' : 'Email & password',
                ),
                if (user.emailVerified)
                  _InfoChip(
                    icon: Icons.verified_outlined,
                    label: 'Verified',
                    color: Colors.green,
                  )
                else
                  const _InfoChip(
                    icon: Icons.error_outline,
                    label: 'Unverified',
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
