import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  french('fr', 'Français', 'Bonjour'),
  arabic('ar', 'العربية (الجزائر)', 'مرحبا'),
  kabyle('ber', 'Taqbaylit (Kabyle)', 'Ansuf yis-wen'),
  english('en', 'English', 'Welcome');

  final String code;
  final String label;
  final String greeting;

  const AppLanguage(this.code, this.label, this.greeting);
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.french);

  void setLanguage(AppLanguage lang) {
    state = lang;
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

class AppStrings {
  static String searchHint(AppLanguage lang) => switch (lang) {
        AppLanguage.arabic => 'ابحث عن وجهة أو موقف...',
        AppLanguage.kabyle => 'Nadi ɣef wemkan...',
        AppLanguage.english => 'Search destination or station...',
        AppLanguage.french => 'Rechercher une destination ou station...',
      };

  static String transportTitle(AppLanguage lang) => switch (lang) {
        AppLanguage.arabic => 'حافلات النقل المتصلة (الفورقونات)',
        AppLanguage.kabyle => 'Ifurgunen yellan deg webrid',
        AppLanguage.english => 'Connected Vans & Transport',
        AppLanguage.french => 'Fourgons & Transports Connectés',
      };

  static String driverMode(AppLanguage lang) => switch (lang) {
        AppLanguage.arabic => 'وضع السائق / الناقل',
        AppLanguage.kabyle => 'Addad n uṣawaf',
        AppLanguage.english => 'Driver / Carrier Mode',
        AppLanguage.french => 'Mode Chauffeur / Transporteur',
      };

  static String passengerMode(AppLanguage lang) => switch (lang) {
        AppLanguage.arabic => 'وضع الراكب',
        AppLanguage.kabyle => 'Addad n umsebrid',
        AppLanguage.english => 'Passenger Mode',
        AppLanguage.french => 'Mode Passager',
      };

  static String selectLine(AppLanguage lang) => switch (lang) {
        AppLanguage.arabic => 'اختر خط النقل',
        AppLanguage.kabyle => 'Fren lxiḍ n usikel',
        AppLanguage.english => 'Select Route Line',
        AppLanguage.french => 'Sélectionner la ligne',
      };

  static String visibleOnMap(AppLanguage lang) => switch (lang) {
        AppLanguage.arabic => 'الظهور على الخريطة',
        AppLanguage.kabyle => 'Udem ɣef tkarḍa',
        AppLanguage.english => 'Visible on Map',
        AppLanguage.french => 'Visible sur la carte',
      };

  static String seatsAvailable(AppLanguage lang, int count) => switch (lang) {
        AppLanguage.arabic => '$count مقاعد شاغرة',
        AppLanguage.kabyle => '$count yemkwan d ilemawen',
        AppLanguage.english => '$count seats left',
        AppLanguage.french => '$count places libres',
      };

  static String languageDialogTitle(AppLanguage lang) => switch (lang) {
        AppLanguage.arabic => 'تغيير لغة التطبيق',
        AppLanguage.kabyle => 'Beddel tutlayt',
        AppLanguage.english => 'Change Language',
        AppLanguage.french => 'Changer la langue',
      };
}
