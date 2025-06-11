// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to Gest-Script!';

  @override
  String get onboardingThemeTitle => 'Choose your theme';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get finishButton => 'Get Started';

  @override
  String get importThemes => 'Import Themes';

  @override
  String get exportThemes => 'Export Themes';
}
