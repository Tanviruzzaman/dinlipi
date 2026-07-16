import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/utils/date_group.dart';
import '../../../core/utils/mood.dart';
import '../../entries/data/entry_model.dart';
import '../../entries/providers/entries_providers.dart';
import '../../entries/screens/entry_editor_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  Map<DateTime, List<Entry>> _byDay(List<Entry> entries) {
    final map = <DateTime, List<Entry>>{};
    for (final e in entries) {
      final key = DateGroup.dayOnly(e.createdAt);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  int _dayMood(List<Entry> entries) {
    if (entries.isEmpty) return 3;
    final sum = entries.fold<int>(0, (acc, e) => acc + e.mood);
    return (sum / entries.length).round().clamp(Mood.min, Mood.max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(entriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (entries) {
          final byDay = _byDay(entries);
          List<Entry> eventsFor(DateTime day) =>
              byDay[DateGroup.dayOnly(day)] ?? const [];

          final selected = _selectedDay ?? _focusedDay;

          final dayEntries = List<Entry>.of(eventsFor(selected))
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<Entry>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _format,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                      CalendarFormat.twoWeeks: '2 weeks',
                      CalendarFormat.week: 'Week',
                    },
                    selectedDayPredicate: (day) =>
                        DateGroup.isSameDay(selected, day),
                    eventLoader: eventsFor,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) =>
                        setState(() => _format = format),
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders<Entry>(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Mood.color(_dayMood(events)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: dayEntries.isEmpty
                    ? Center(
                        child: Text(
                          'No entries on ${DateGroup.header(selected)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: dayEntries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = dayEntries[i];
                          return Card(
                            child: ListTile(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EntryEditorScreen(entry: e),
                                ),
                              ),
                              leading: Icon(Mood.icon(e.mood),
                                  color: Mood.color(e.mood)),
                              title: Text(
                                e.title.trim().isEmpty
                                    ? 'Untitled'
                                    : e.title.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                e.body.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(DateGroup.time(e.createdAt),
                                  style: theme.textTheme.bodySmall),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
