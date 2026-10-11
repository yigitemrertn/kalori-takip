import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/food_entry.dart';
import '../state/app_state.dart';
import '../utils.dart';

/// Günlük kalori açığı / fazlası grafiği.
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final history = state.history(_days);
    final logged = history.where((d) => d.hasEntries).toList();
    final net = logged.fold<double>(0, (s, d) => s + d.balance);
    final avg = logged.isEmpty ? 0.0 : net / logged.length;
    final avgKcal = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (s, d) => s + d.totals.calories) /
            logged.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Kalori dengesi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 gün')),
              ButtonSegment(value: 14, label: Text('14 gün')),
              ButtonSegment(value: 30, label: Text('30 gün')),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() => _days = s.first),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
              child: Column(
                children: [
                  SizedBox(height: 260, child: _BalanceChart(history)),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Legend(color: AppColors.deficit, label: 'Açık'),
                      SizedBox(width: 20),
                      _Legend(color: AppColors.surplus, label: 'Fazla'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Toplam denge',
                  value: _signed(net),
                  color: net > 0 ? AppColors.surplus : AppColors.deficit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Günlük ort.',
                  value: _signed(avg),
                  color: avg > 0 ? AppColors.surplus : AppColors.deficit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Ort. alınan',
                  value: '${fmtKcal(avgKcal)} kcal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${logged.length}/$_days gün kayıtlı. Kayıt olmayan günler '
            'hesaba katılmaz. Hedef: ${fmtKcal(state.targets!.calories)} kcal/gün',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text('Günlük detay', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final d in logged.reversed)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(DateFormat('d MMMM, EEEE', 'tr_TR').format(d.day)),
                subtitle: Text('${fmtKcal(d.totals.calories)} kcal alındı'),
                trailing: Text(
                  _signed(d.balance),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: d.balance > 0
                        ? AppColors.surplus
                        : AppColors.deficit,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (logged.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Bu dönemde kayıt yok.', textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  static String _signed(double v) =>
      '${v > 0 ? '+' : v < 0 ? '−' : ''}${fmtKcal(v.abs())} kcal';
}

class _BalanceChart extends StatelessWidget {
  const _BalanceChart(this.history);

  final List<DailySummary> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = [for (final d in history) d.hasEntries ? d.balance : 0.0];
    var maxAbs = values.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
    maxAbs = maxAbs < 500 ? 500 : (maxAbs / 250).ceil() * 250.0;
    final labelEvery = history.length <= 7 ? 1 : (history.length <= 14 ? 2 : 5);
    final barWidth = history.length <= 7 ? 22.0 : (history.length <= 14 ? 12.0 : 6.0);

    return BarChart(
      BarChartData(
        minY: -maxAbs,
        maxY: maxAbs,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxAbs / 2,
          getDrawingHorizontalLine: (v) => FlLine(
            color: v == 0
                ? theme.colorScheme.outline
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: v == 0 ? 1.5 : 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: maxAbs / 2,
              getTitlesWidget: (v, meta) => Text(
                fmtKcal(v),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                final fromEnd = history.length - 1 - i;
                if (i < 0 || i >= history.length || fromEnd % labelEvery != 0) {
                  return const SizedBox.shrink();
                }
                final day = history[i].day;
                final label = history.length <= 7
                    ? DateFormat.E('tr_TR').format(day)
                    : DateFormat('d/M').format(day);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = history[group.x];
              final text = d.hasEntries
                  ? '${DateFormat('d MMM', 'tr_TR').format(d.day)}\n'
                      '${d.balance > 0 ? '+' : '−'}${fmtKcal(d.balance.abs())} kcal'
                  : '${DateFormat('d MMM', 'tr_TR').format(d.day)}\nKayıt yok';
              return BarTooltipItem(
                text,
                TextStyle(color: theme.colorScheme.onInverseSurface),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < history.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: barWidth,
                  color: values[i] > 0 ? AppColors.surplus : AppColors.deficit,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, this.color});

  final String title;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
