import 'package:flutter/material.dart';

/// Shared confirmation dialog for signing out. Returns true if confirmed.
Future<bool> confirmSignOut(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('Are you sure you want to sign out? '
          'You can sign back in anytime.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  return result ?? false;
}
