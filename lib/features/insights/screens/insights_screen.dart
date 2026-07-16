import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/mood.dart';
import '../../entries/providers/entries_providers.dart';
import '../insights_data.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (entries) {
          final data = InsightsData.from(entries);
          if (data.isEmpty) return const _EmptyInsights();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              _StatRow(data: data),
              const SizedBox(height: 20),
              _AverageMoodCard(data: data),
              const SizedBox(height: 20),
              _SectionLabel('Mood — last 30 days'),
              _MoodChartCard(data: data),
              const SizedBox(height: 20),
              _SectionLabel('Mood breakdown'),
              _MoodBreakdownCard(data: data),
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_outlined,
            value: '${data.currentStreak}',
            label: data.currentStreak == 1 ? 'day streak' : 'day streak',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.book_outlined,
            value: '${data.totalEntries}',
            label: 'total',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_month_outlined,
            value: '${data.entriesThisMonth}',
            label: 'this month',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AverageMoodCard extends StatelessWidget {
  const _AverageMoodCard({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rounded = data.averageMood.round().clamp(Mood.min, Mood.max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Mood.icon(rounded), color: Mood.color(rounded), size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Average mood',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                Text(
                  '${data.averageMood.toStringAsFixed(1)} · ${Mood.label(rounded)}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChartCard extends StatelessWidget {
  const _MoodChartCard({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final spots = <FlSpot>[];
    for (var i = 0; i < data.last30DaysMood.length; i++) {
      final v = data.last30DaysMood[i];
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
        child: SizedBox(
          height: 200,
          child: spots.isEmpty
              ? Center(
                  child: Text('No entries in the last 30 days',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                )
              : LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 29,
                    minY: 0.5,
                    maxY: 5.5,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            if (value < 1 || value > 5) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toInt().toString(),
                              style: theme.textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        barWidth: 3,
                        color: theme.colorScheme.primary,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _MoodBreakdownCard extends StatelessWidget {
  const _MoodBreakdownCard({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = data.moodCounts.values.fold<int>(0, (m, v) => v > m ? v : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: Mood.values.reversed.map((m) {
            final count = data.moodCounts[m] ?? 0;
            final fraction = maxCount == 0 ? 0.0 : count / maxCount;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Mood.icon(m), color: Mood.color(m), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 10,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: Mood.color(m),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 24,
                    child: Text('$count',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
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

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('No insights yet',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Write a few entries and your mood trends,\nstreak, and stats will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
