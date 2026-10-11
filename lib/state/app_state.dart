import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_entry.dart';
import '../models/user_profile.dart';
import '../services/nutrition_calculator.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Uygulamanın tüm durumu. Veriler cihazda (SharedPreferences) saklanır.
class AppState extends ChangeNotifier {
  static const _profileKey = 'profile';
  static const _entriesKey = 'entries';

  SharedPreferences? _prefs;
  UserProfile? _profile;
  List<FoodEntry> _entries = [];

  UserProfile? get profile => _profile;
  List<FoodEntry> get entries => List.unmodifiable(_entries);

  NutritionTargets? get targets =>
      _profile == null ? null : NutritionCalculator.calculate(_profile!);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final profileJson = _prefs!.getString(_profileKey);
    if (profileJson != null) {
      _profile = UserProfile.fromJson(jsonDecode(profileJson));
    }
    final entriesJson = _prefs!.getString(_entriesKey);
    if (entriesJson != null) {
      _entries = (jsonDecode(entriesJson) as List)
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _prefs?.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> addEntry(FoodEntry entry) async {
    _entries.add(entry);
    await _persistEntries();
  }

  Future<void> updateEntry(FoodEntry entry) async {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i == -1) return;
    _entries[i] = entry;
    await _persistEntries();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persistEntries();
  }

  Future<void> resetAll() async {
    _profile = null;
    _entries = [];
    notifyListeners();
    await _prefs?.clear();
  }

  Future<void> _persistEntries() async {
    notifyListeners();
    await _prefs?.setString(
      _entriesKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  List<FoodEntry> entriesFor(DateTime day) {
    final d = dateOnly(day);
    return _entries.where((e) => dateOnly(e.eatenAt) == d).toList()
      ..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
  }

  Totals totalsFor(DateTime day) =>
      entriesFor(day).fold(const Totals(), (t, e) => t + e);

  /// Bugün dahil son [days] günün özeti (eskiden yeniye).
  List<DailySummary> history(int days) {
    final target = targets?.calories ?? 0;
    final today = dateOnly(DateTime.now());
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final list = entriesFor(day);
      return DailySummary(
        day: day,
        totals: list.fold(const Totals(), (t, e) => t + e),
        target: target,
        hasEntries: list.isNotEmpty,
      );
    });
  }
}

/// AppState'i widget ağacına taşır: `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
