import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/food_entry.dart';
import '../state/app_state.dart';
import '../utils.dart';
import 'food_entry_sheet.dart';

/// Günlük: seçili günün özeti ve yenen/içilenler listesi.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _day = dateOnly(DateTime.now());

  bool get _isToday => _day == dateOnly(DateTime.now());

  void _shiftDay(int delta) {
    final next = _day.add(Duration(days: delta));
    if (next.isAfter(dateOnly(DateTime.now()))) return;
    setState(() => _day = dateOnly(next));
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _day = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final targets = state.targets!;
    final entries = state.entriesFor(_day);
    final totals = state.totalsFor(_day);
    final dayLabel = _isToday
        ? 'Bugün'
        : DateFormat('d MMMM y, EEEE', 'tr_TR').format(_day);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shiftDay(-1),
            ),
            Flexible(
              child: TextButton(
                onPressed: _pickDay,
                child: Text(dayLabel, overflow: TextOverflow.ellipsis),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _isToday ? null : () => _shiftDay(1),
            ),
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showFoodEntrySheet(context, day: _day),
        icon: const Icon(Icons.add),
        label: const Text('Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _SummaryCard(
            totals: totals,
            targetKcal: targets.calories,
            targetProtein: targets.protein,
            targetCarbs: targets.carbs,
            targetFat: targets.fat,
            isToday: _isToday,
          ),
          const SizedBox(height: 16),
          Text(
            'Yenen / içilenler (${entries.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.restaurant,
                      size: 48, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 8),
                  const Text('Henüz kayıt yok. "Ekle" ile başla.'),
                ],
              ),
            )
          else
            for (final e in entries)
              _EntryTile(
                entry: e,
                onTap: () =>
                    showFoodEntrySheet(context, day: _day, existing: e),
                onDelete: () => _delete(state, e),
              ),
        ],
      ),
    );
  }

  void _delete(AppState state, FoodEntry e) {
    state.deleteEntry(e.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('"${e.name}" silindi'),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () => state.addEntry(e),
        ),
      ));
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totals,
    required this.targetKcal,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.isToday,
  });

  final Totals totals;
  final double targetKcal, targetProtein, targetCarbs, targetFat;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = totals.calories - targetKcal;
    final isSurplus = balance > 0;
    final balanceColor = isSurplus ? AppColors.surplus : AppColors.deficit;
    final progress = targetKcal == 0 ? 0.0 : totals.calories / targetKcal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: progress > 1
                            ? AppColors.surplus
                            : theme.colorScheme.primary,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(fmtKcal(totals.calories),
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text('/ ${fmtKcal(targetKcal)} kcal',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSurplus ? 'Kalori fazlası' : 'Kalori açığı',
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        '${isSurplus ? '+' : '−'}${fmtKcal(balance.abs())} kcal',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: balanceColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSurplus
                            ? 'Koruma hedefinin üzerindesin.'
                            : isToday
                                ? 'Kalan: ${fmtKcal(balance.abs())} kcal'
                                : 'Koruma hedefinin altında kaldın.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MacroBar('Protein', totals.protein, targetProtein,
                AppColors.protein),
            _MacroBar(
                'Karbonhidrat', totals.carbs, targetCarbs, AppColors.carbs),
            _MacroBar('Yağ', totals.fat, targetFat, AppColors.fat),
          ],
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar(this.label, this.value, this.target, this.color);

  final String label;
  final double value, target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = target == 0 ? 0.0 : value / target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              Text('${fmtGram(value)} / ${fmtKcal(target)} g'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final FoodEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          onTap: onTap,
          title: Text(entry.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${DateFormat.Hm('tr_TR').format(entry.eatenAt)}  ·  '
            'P ${fmtGram(entry.protein)}g  ·  '
            'K ${fmtGram(entry.carbs)}g  ·  '
            'Y ${fmtGram(entry.fat)}g',
          ),
          trailing: Text(
            '${fmtKcal(entry.calories)} kcal',
            style: theme.textTheme.titleSmall,
          ),
        ),
      ),
    );
  }
}
