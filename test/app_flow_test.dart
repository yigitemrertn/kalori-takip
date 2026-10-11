import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalori_takip/main.dart';
import 'package:kalori_takip/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Onboarding → yemek ekleme → grafik akışı', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr_TR');
    final state = AppState();
    await state.load();

    await tester.pumpWidget(KaloriApp(state: state));
    expect(find.text('Hoş geldin!'), findsOneWidget);

    // Profil bilgileri
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '30'); // yaş
    await tester.enterText(fields.at(1), '180'); // boy
    await tester.enterText(fields.at(2), '80'); // kilo
    await tester.tap(find.text('Orta hareketli'));
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Hesapla ve başla'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Hesapla ve başla'));
    await tester.pumpAndSettle();

    // Günlük ekranı: hedef 1780*1.55 = 2759 kcal
    expect(find.text('Henüz kayıt yok. "Ekle" ile başla.'), findsOneWidget);
    expect(find.text('/ 2.759 kcal'), findsOneWidget);

    // Yemek ekle
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    final sheetFields = find.byType(TextFormField);
    await tester.enterText(sheetFields.at(0), 'Tavuk pilav');
    await tester.enterText(sheetFields.at(1), '40'); // protein
    await tester.enterText(sheetFields.at(2), '80'); // karb
    await tester.enterText(sheetFields.at(3), '15'); // yağ
    await tester.tap(find.text('Makrodan\nhesapla'));
    await tester.pump();
    expect(find.text('615'), findsOneWidget); // 160+320+135
    await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
    await tester.pumpAndSettle();

    expect(find.text('Tavuk pilav'), findsOneWidget);
    expect(find.text('Kalori açığı'), findsOneWidget);
    expect(state.entries.length, 1);

    // Grafik sekmesi
    await tester.tap(find.text('Grafik'));
    await tester.pumpAndSettle();
    expect(find.text('Kalori dengesi'), findsOneWidget);
    expect(find.textContaining('1/7 gün kayıtlı'), findsOneWidget);
  });
}
