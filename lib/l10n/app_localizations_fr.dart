// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcomeTitle => 'Bienvenue dans Gest-Script !';

  @override
  String get onboardingThemeTitle => 'Choisissez votre thème';

  @override
  String get onboardingLanguageTitle => 'Choisissez votre langue';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get finishButton => 'Commencer';

  @override
  String get importThemes => 'Importer des thèmes';

  @override
  String get exportThemes => 'Exporter des thèmes';
}
