// lib/ui/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/providers/settings_provider.dart';
import 'package:gest_script/l10n/app_localizations.dart';
import 'package:gest_script/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:gest_script/generated/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  ThemeMode _selectedTheme = ThemeMode.dark;
  Locale _selectedLocale = const Locale('fr');

  @override
  Widget build(BuildContext context) {
    // Nous utilisons les localisations générées
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_stories,
                size: 60,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.welcomeTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Sélecteur de thème
              Text(
                l10n.onboardingThemeTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                    icon: const Icon(Icons.wb_sunny),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                    icon: const Icon(Icons.nightlight_round),
                  ),
                ],
                selected: {_selectedTheme},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  setState(() {
                    _selectedTheme = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 30),

              // Sélecteur de langue
              Text(
                l10n.onboardingLanguageTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              SegmentedButton<Locale>(
                segments: const <ButtonSegment<Locale>>[
                  ButtonSegment<Locale>(
                    value: Locale('fr'),
                    label: Text('Français'),
                    icon: Text('🇫🇷'),
                  ),
                  ButtonSegment<Locale>(
                    value: Locale('en'),
                    label: Text('English'),
                    icon: Text('🇬🇧'),
                  ),
                ],
                selected: {_selectedLocale},
                onSelectionChanged: (Set<Locale> newSelection) {
                  setState(() {
                    _selectedLocale = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 50),

              // Bouton de validation
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: Text(l10n.finishButton),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: _completeSetup,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeSetup() async {
    // Mettre à jour les providers
    ref.read(themeNotifierProvider.notifier).setTheme(_selectedTheme);
    ref.read(localeNotifierProvider.notifier).setLocale(_selectedLocale);

    // Marquer la configuration comme terminée
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedSetup', true);

    // Naviguer vers l'écran d'accueil
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
}
