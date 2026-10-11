# Kalori Takip

iPhone ve Android için kalori & makro takip uygulaması (Flutter).

## Özellikler
- **İlk açılış:** cinsiyet, yaş, boy, kilo ve günlük aktivite seviyesi alınır.
- **Hedef hesaplama (kilo koruma):**
  - BMR — Mifflin-St Jeor: `10×kg + 6.25×cm − 5×yaş (+5 erkek / −161 kadın)`
  - Günlük kalori = BMR × aktivite çarpanı (1.2 – 1.9)
  - Protein 1.6 g/kg · Yağ kalorinin %25'i · Karbonhidrat kalan kalori
- **Günlük:** yemek/içecek adı, kalori, protein, karbonhidrat, yağ girişi; düzenleme, kaydırarak silme (geri alma ile), geçmiş günlere geçiş. "Makrodan hesapla" butonu kaloriyi 4/4/9 kuralıyla doldurur.
- **Gün sonu dengesi:** hedefe göre kalori açığı (yeşil) / fazlası (kırmızı).
- **Grafik:** son 7/14/30 günün açık/fazla bar grafiği, toplam ve ortalama denge.
- Veriler yalnızca cihazda saklanır (`shared_preferences`).

## Yapı
```
lib/
  main.dart                     # Uygulama girişi, tema, TR yerelleştirme
  models/                       # UserProfile, FoodEntry, Totals, DailySummary
  services/nutrition_calculator.dart
  state/app_state.dart          # Durum + yerel kayıt
  screens/                      # Onboarding/profil formu, Günlük, Grafik, Profil
test/widget_test.dart           # Hesaplama testleri
```

## Kurulum (internet hızlı olduğunda)
1. Flutter SDK'yı kurun: https://docs.flutter.dev/get-started/install/windows
   (zip'i `C:\Users\<kullanıcı>\flutter` içine açıp `bin` klasörünü PATH'e ekleyin)
2. Bu klasörde platform dosyalarını oluşturun (mevcut kod dosyalarının üzerine yazmaz):
   ```
   flutter create . --project-name kalori_takip --platforms android,ios --org com.kaloritakip
   ```
3. Paketleri indirin ve test edin:
   ```
   flutter pub get
   flutter test
   ```
4. Çalıştırın: Android telefonu USB hata ayıklama ile bağlayıp `flutter run`.

> iOS derlemesi için macOS + Xcode gerekir (Windows'ta iOS derlenemez).
