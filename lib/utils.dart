import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _intFmt = NumberFormat('#,##0', 'tr_TR');
final _decFmt = NumberFormat('#,##0.#', 'tr_TR');

String fmtKcal(num v) => _intFmt.format(v.round());
String fmtGram(num v) => _decFmt.format(v);

/// Form alanlarını doldurmak için binlik ayırıcısız metin.
String inputText(num v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// "12,5" ve "12.5" girişlerini destekler.
double? parseNum(String? s) {
  if (s == null) return null;
  final t = s.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

class AppColors {
  static const protein = Color(0xFF3B82F6);
  static const carbs = Color(0xFFF59E0B);
  static const fat = Color(0xFFEC4899);
  static const deficit = Color(0xFF16A34A);
  static const surplus = Color(0xFFDC2626);
}
