import 'package:flutter/material.dart';

import '../services/nutrition_calculator.dart';
import '../state/app_state.dart';
import '../utils.dart';
import 'profile_form_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile!;
    final t = state.targets!;
    final theme = Theme.of(context);

    Widget infoRow(String label, String value) => ListTile(
          dense: true,
          title: Text(label),
          trailing: Text(value, style: theme.textTheme.titleSmall),
        );

    Widget macroTile(String label, double grams, double kcalPerGram,
        Color color, String note) {
      final pct = t.calories == 0 ? 0 : grams * kcalPerGram / t.calories * 100;
      return ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 8),
        title: Text(label),
        subtitle: Text(note),
        trailing: Text(
          '${fmtKcal(grams)} g\n%${pct.round()}',
          textAlign: TextAlign.right,
          style: theme.textTheme.titleSmall,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & hedefler'),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProfileFormScreen(initial: p),
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Günlük koruma kalorin',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${fmtKcal(t.calories)} kcal',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Bazal metabolizma (BMR): ${fmtKcal(t.bmr)} kcal'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                macroTile('Protein', t.protein, 4, AppColors.protein,
                    '${fmtGram(NutritionCalculator.proteinPerKg)} g × kg vücut ağırlığı'),
                macroTile('Karbonhidrat', t.carbs, 4, AppColors.carbs,
                    'Kalan kalori'),
                macroTile('Yağ', t.fat, 9, AppColors.fat,
                    'Kalorinin %${(NutritionCalculator.fatRatio * 100).round()}\'i'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                infoRow('Cinsiyet', p.gender.label),
                infoRow('Yaş', '${p.age}'),
                infoRow('Boy', '${fmtGram(p.heightCm)} cm'),
                infoRow('Kilo', '${fmtGram(p.weightKg)} kg'),
                infoRow('Aktivite', p.activity.label),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hesaplama Mifflin-St Jeor formülü ve aktivite çarpanı ile yapılır. '
            'Değerler tahminidir; sağlık durumun için bir uzmana danış.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, state),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Tüm verileri sıfırla'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emin misin?'),
        content: const Text(
            'Profilin ve tüm yemek kayıtların kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) await state.resetAll();
  }
}
