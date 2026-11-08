import 'package:flutter/material.dart';

class TimizarStrings {
  final Locale locale;
  TimizarStrings(this.locale);

  static TimizarStrings of(BuildContext context) {
    return Localizations.of<TimizarStrings>(context, TimizarStrings) ??
        TimizarStrings(const Locale('fr'));
  }

  String get searchDestination => switch (locale.languageCode) {
    'ar' => 'البحث عن وجهة',
    'en' => 'Search destination',
    _ => 'Rechercher',
  };

  String get addHome => switch (locale.languageCode) {
    'ar' => 'إضافة المنزل',
    'en' => 'Add home',
    _ => 'Ajouter domicile',
  };

  String get addWork => switch (locale.languageCode) {
    'ar' => 'إضافة العمل',
    'en' => 'Add work',
    _ => 'Ajouter travail',
  };

  String get recents => switch (locale.languageCode) {
    'ar' => 'الأماكن الأخيرة',
    'en' => 'Recent places',
    _ => 'Récents',
  };

  String get requestRide => switch (locale.languageCode) {
    'ar' => 'طلب سيارة تيميزار',
    'en' => 'Request Timizar',
    _ => 'Commander Timizar',
  };

  String get searchingDriver => switch (locale.languageCode) {
    'ar' => 'جاري البحث عن سائق قريب...',
    'en' => 'Searching for a driver...',
    _ => 'Recherche d\'un chauffeur...',
  };

  String get driverArriving => switch (locale.languageCode) {
    'ar' => 'السائق في الطريق إليك',
    'en' => 'Driver is arriving',
    _ => 'Chauffeur en route',
  };

  String get tripInProgress => switch (locale.languageCode) {
    'ar' => 'الرحلة جارية',
    'en' => 'Trip in progress',
    _ => 'Course en cours',
  };

  String get tripCompleted => switch (locale.languageCode) {
    'ar' => 'تم إنهاء الرحلة بنجاح',
    'en' => 'Trip completed',
    _ => 'Course terminée',
  };

  String get online => switch (locale.languageCode) {
    'ar' => 'متصل',
    'en' => 'Online',
    _ => 'En ligne',
  };

  String get offline => switch (locale.languageCode) {
    'ar' => 'غير متصل',
    'en' => 'Offline',
    _ => 'Hors ligne',
  };

  String get goOnline => switch (locale.languageCode) {
    'ar' => 'ابدأ العمل (اتصال)',
    'en' => 'Go online',
    _ => 'Passer en ligne',
  };

  String get accept => switch (locale.languageCode) {
    'ar' => 'قبول',
    'en' => 'Accept',
    _ => 'Accepter',
  };

  String get decline => switch (locale.languageCode) {
    'ar' => 'رفض',
    'en' => 'Decline',
    _ => 'Refuser',
  };

  String get emergencySos => switch (locale.languageCode) {
    'ar' => 'طوارئ SOS',
    'en' => 'Emergency SOS',
    _ => 'Urgence SOS',
  };

  String get continueWithGoogle => switch (locale.languageCode) {
    'ar' => 'المتابعة باستخدام Google',
    'en' => 'Continue with Google',
    _ => 'Continuer avec Google',
  };
}

class TimizarLocalizationsDelegate extends LocalizationsDelegate<TimizarStrings> {
  const TimizarLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'ar', 'en'].contains(locale.languageCode);

  @override
  Future<TimizarStrings> load(Locale locale) async => TimizarStrings(locale);

  @override
  bool shouldReload(TimizarLocalizationsDelegate old) => false;
}
