import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../providers/auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldown = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _check(silent: true),
    );

    _startCooldown();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        if (mounted) setState(() => _cooldown--);
      }
    });
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final verified =
          await ref.read(authRepositoryProvider).reloadAndCheckVerified();
      if (verified) {
        _pollTimer?.cancel();

        ref.invalidate(authStateProvider);
      } else if (!silent && mounted) {
        _snack('Not verified yet. Check your inbox (and spam folder).');
      }
    } catch (_) {
      if (!silent && mounted) _snack('Could not check right now. Try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) _snack('Verification email sent.');
      _startCooldown();
    } catch (e) {
      if (mounted) _snack(authErrorMessage(e));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.read(authRepositoryProvider).currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.mark_email_unread_outlined,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 20),
                  Text('Verify your email',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      children: [
                        const TextSpan(
                            text: 'We sent a verification link to\n'),
                        TextSpan(
                          text: email,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                            text: '.\n\nOpen it, then come back here — the app '
                                'unlocks automatically once you’re verified.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _checking ? null : () => _check(),
                    icon: _checking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text("I've verified — continue"),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cooldown > 0 ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.mail_outline),
                    label: Text(_cooldown > 0
                        ? 'Resend email (${_cooldown}s)'
                        : 'Resend email'),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    child: const Text('Use a different account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
