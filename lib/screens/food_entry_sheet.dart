import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/food_entry.dart';
import '../services/nutrition_calculator.dart';
import '../state/app_state.dart';
import '../utils.dart';

/// Yemek/içecek ekleme veya düzenleme alt sayfası.
Future<void> showFoodEntrySheet(
  BuildContext context, {
  required DateTime day,
  FoodEntry? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _FoodEntryForm(day: day, existing: existing),
  );
}

class _FoodEntryForm extends StatefulWidget {
  const _FoodEntryForm({required this.day, this.existing});

  final DateTime day;
  final FoodEntry? existing;

  @override
  State<_FoodEntryForm> createState() => _FoodEntryFormState();
}

class _FoodEntryFormState extends State<_FoodEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _kcal = TextEditingController(text: e == null ? '' : inputText(e.calories));
    _protein = TextEditingController(text: e == null ? '' : inputText(e.protein));
    _carbs = TextEditingController(text: e == null ? '' : inputText(e.carbs));
    _fat = TextEditingController(text: e == null ? '' : inputText(e.fat));
  }

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  double _macro(TextEditingController c) => parseNum(c.text) ?? 0;

  void _fillKcalFromMacros() {
    final kcal = NutritionCalculator.caloriesFromMacros(
        _macro(_protein), _macro(_carbs), _macro(_fat));
    setState(() => _kcal.text = kcal.round().toString());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final now = DateTime.now();
    final e = widget.existing;
    final entry = FoodEntry(
      id: e?.id ?? now.microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      calories: parseNum(_kcal.text)!,
      protein: _macro(_protein),
      carbs: _macro(_carbs),
      fat: _macro(_fat),
      eatenAt: e?.eatenAt ??
          DateTime(widget.day.year, widget.day.month, widget.day.day,
              now.hour, now.minute),
    );
    if (e == null) {
      await state.addEntry(entry);
    } else {
      await state.updateEntry(entry);
    }
    if (mounted) Navigator.of(context).pop();
  }

  String? _optionalNum(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final v = parseNum(s);
    if (v == null || v < 0) return 'Geçersiz';
    return null;
  }

  Widget _numField(TextEditingController c, String label, String suffix,
      {Color? color, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        prefixIcon: color == null
            ? null
            : Icon(Icons.circle, size: 12, color: color),
        prefixIconConstraints: const BoxConstraints(minWidth: 32),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: TextInputAction.next,
      validator: validator ?? _optionalNum,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Kaydı düzenle' : 'Yemek / içecek ekle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: !isEdit,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'İsim',
                  hintText: 'ör. Yulaf ezmesi, Ayran',
                  border: OutlineInputBorder(),
                ),
                validator: (s) =>
                    (s == null || s.trim().isEmpty) ? 'İsim girin' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numField(_protein, 'Protein', 'g',
                        color: AppColors.protein),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _numField(_carbs, 'Karb.', 'g',
                        color: AppColors.carbs),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _numField(_fat, 'Yağ', 'g', color: AppColors.fat),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _numField(
                      _kcal,
                      'Kalori',
                      'kcal',
                      validator: (s) {
                        final v = parseNum(s);
                        if (v == null) return 'Kalori girin';
                        if (v < 0) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OutlinedButton.icon(
                      onPressed: _fillKcalFromMacros,
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: const Text('Makrodan\nhesapla',
                          textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isEdit ? 'Güncelle' : 'Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
