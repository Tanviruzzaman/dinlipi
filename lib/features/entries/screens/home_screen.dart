import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_group.dart';
import '../../../core/utils/mood.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/entry_model.dart';
import '../providers/entries_providers.dart';
import 'entry_editor_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openEditor(BuildContext context, {Entry? entry}) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EntryEditorScreen(entry: entry)),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dinlipi'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (await confirmSignOut(context)) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: '$err'),
        data: (entries) {
          if (entries.isEmpty) return const _EmptyState();
          return _EntryList(
            entries: entries,
            onTap: (e) => _openEditor(context, entry: e),
            onDelete: (e) async {
              final ok = await _confirmDelete(context);
              if (!ok) return false;
              final uid = ref.read(currentUidProvider);
              if (uid == null) return false;
              await ref.read(entriesRepositoryProvider).deleteEntry(uid, e.id);
              return true;
            },
          );
        },
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.entries,
    required this.onTap,
    required this.onDelete,
  });

  final List<Entry> entries;
  final void Function(Entry) onTap;

  /// Returns true if the entry was actually deleted.
  final Future<bool> Function(Entry) onDelete;

  @override
  Widget build(BuildContext context) {
    // Build a flat list of [header, ...cards, header, ...cards].
    final items = <_ListItem>[];
    String? lastHeader;
    for (final e in entries) {
      final header = DateGroup.header(e.createdAt);
      if (header != lastHeader) {
        items.add(_HeaderItem(header));
        lastHeader = header;
      }
      items.add(_EntryItem(e));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _HeaderItem) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 8 : 24, bottom: 8),
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        final entry = (item as _EntryItem).entry;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey(entry.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            confirmDismiss: (_) => onDelete(entry),
            child: _EntryCard(entry: entry, onTap: () => onTap(entry)),
          ),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onTap});

  final Entry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = entry.title.trim().isEmpty ? 'Untitled' : entry.title.trim();

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (entry.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.body.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      DateGroup.time(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Mood.icon(entry.mood),
                  color: Mood.color(entry.mood), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('Your journal is empty',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Tap “New entry” to write your first note.\nHow are you feeling today?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('Could not load entries\n$message',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// --- Small helper types for building the grouped list ---
sealed class _ListItem {
  const _ListItem();
}

class _HeaderItem extends _ListItem {
  const _HeaderItem(this.label);
  final String label;
}

class _EntryItem extends _ListItem {
  const _EntryItem(this.entry);
  final Entry entry;
}
