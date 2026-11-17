import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'translations/account_translations.dart';
import 'translations/address_translations.dart';
import 'translations/auth_translations.dart';
import 'translations/cart_translations.dart';
import 'translations/catalog_translations.dart';
import 'translations/common_translations.dart';
import 'translations/home_translations.dart';
import 'translations/favorites_translations.dart';
import 'translations/navigation_translations.dart';
import 'translations/onboarding_translations.dart';

/// Lightweight, official Flutter localization delegate backed by feature
/// catalogs. It keeps the public API stable while allowing ARB generation to
/// be introduced when the translation team is connected.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  AuthTranslations get auth => AuthTranslations(locale);
  CommonTranslations get common => CommonTranslations(locale);
  HomeTranslations get home => HomeTranslations(locale);
  CatalogTranslations get catalog => CatalogTranslations(locale);
  CartTranslations get cart => CartTranslations(locale);
  FavoritesTranslations get favorites => FavoritesTranslations(locale);
  OnboardingTranslations get onboarding => OnboardingTranslations(locale);
  AddressTranslations get address => AddressTranslations(locale);
  NavigationTranslations get navigation => NavigationTranslations(locale);
  AccountTranslations get account => AccountTranslations(locale);

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    final result =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'AppLocalizations is missing from the widget tree.');
    return result!;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
