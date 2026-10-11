import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../utils.dart';

/// İlk açılışta (onboarding) ve profil düzenlemede kullanılan form.
class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, this.initial});

  /// Null ise ilk kurulum (onboarding) modundadır.
  final UserProfile? initial;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late Gender _gender;
  late ActivityLevel _activity;

  bool get _isOnboarding => widget.initial == null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _age = TextEditingController(text: p?.age.toString() ?? '');
    _height = TextEditingController(text: p == null ? '' : inputText(p.heightCm));
    _weight = TextEditingController(text: p == null ? '' : inputText(p.weightKg));
    _gender = p?.gender ?? Gender.male;
    _activity = p?.activity ?? ActivityLevel.light;
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  String? Function(String?) _rangeValidator(double min, double max) {
    return (s) {
      final v = parseNum(s);
      if (v == null) return 'Gerekli alan';
      if (v < min || v > max) return '${fmtGram(min)} - ${fmtGram(max)} arası girin';
      return null;
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = UserProfile(
      age: parseNum(_age.text)!.round(),
      heightCm: parseNum(_height.text)!,
      weightKg: parseNum(_weight.text)!,
      gender: _gender,
      activity: _activity,
    );
    await AppScope.of(context).saveProfile(profile);
    if (!_isOnboarding && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decimalInput = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOnboarding ? 'Hoş geldin!' : 'Profili düzenle'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_isOnboarding) ...[
                Text(
                  'Kilonu sağlıklı şekilde koruman için gereken günlük kalori, '
                  'protein, karbonhidrat ve yağ miktarını hesaplayalım.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],
              Text('Cinsiyet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<Gender>(
                segments: [
                  for (final g in Gender.values)
                    ButtonSegment(
                      value: g,
                      label: Text(g.label),
                      icon: Icon(g == Gender.male ? Icons.male : Icons.female),
                    ),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _age,
                decoration: const InputDecoration(
                  labelText: 'Yaş',
                  suffixText: 'yıl',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _rangeValidator(10, 110),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _height,
                      decoration: const InputDecoration(
                        labelText: 'Boy',
                        suffixText: 'cm',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimalInput,
                      validator: _rangeValidator(100, 250),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      decoration: const InputDecoration(
                        labelText: 'Kilo',
                        suffixText: 'kg',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimalInput,
                      validator: _rangeValidator(30, 300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Günlük aktivite', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              RadioGroup<ActivityLevel>(
                groupValue: _activity,
                onChanged: (v) => setState(() => _activity = v!),
                child: Column(
                  children: [
                    for (final a in ActivityLevel.values)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: a == _activity
                            ? theme.colorScheme.primaryContainer
                            : null,
                        child: RadioListTile<ActivityLevel>(
                          value: a,
                          title: Text(a.label),
                          subtitle: Text(a.description),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.calculate),
                label: Text(_isOnboarding ? 'Hesapla ve başla' : 'Kaydet'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
