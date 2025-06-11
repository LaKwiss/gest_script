// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/l10n/app_localizations.dart';
import 'package:gest_script/ui/home_screen.dart';
import 'package:gest_script/ui/onboarding_screen.dart';
import 'package:gest_script/ui/theme_managment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
//import 'package:gest_script/generated/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool hasCompletedSetup = prefs.getBool('hasCompletedSetup') ?? false;

  final container = ProviderContainer();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.hide();
    });

    SystemTray.init(container);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(hasCompletedSetup: hasCompletedSetup),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool hasCompletedSetup;

  const MyApp({super.key, required this.hasCompletedSetup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On récupère l'état complet du thème
    final themeState = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final navigatorKey = ref.watch(navigatorKeyProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,

      // Le thème appliqué est maintenant celui qui est actif dans notre état
      theme: themeState.activeThemeData,
      // On peut laisser les thèmes par défaut au cas où
      darkTheme: defaultDarkTheme,

      home: hasCompletedSetup ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}

class SystemTray with TrayListener {
  static final SystemTray _instance = SystemTray._internal();
  static late ProviderContainer _container;

  factory SystemTray() {
    return _instance;
  }

  SystemTray._internal();

  static void init(ProviderContainer container) {
    _container = container;
    _instance._createTray();
  }

  void _createTray() async {
    await trayManager.setIcon('assets/app_icon.ico');
    Menu menu = await _getMenu();
    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }

  Future<Menu> _getMenu() async {
    return Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Afficher/Cacher'),
        MenuItem.separator(),
        MenuItem(key: 'manage_themes', label: 'Gérer les thèmes'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Quitter'),
      ],
    );
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.isVisible().then((visible) {
      visible ? windowManager.hide() : windowManager.show();
    });
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final context = _container.read(navigatorKeyProvider).currentContext;

    if (context == null) {
      debugPrint("Le contexte du navigateur n'est pas disponible.");
      return;
    }

    switch (menuItem.key) {
      case 'show_window':
        windowManager.isVisible().then((visible) {
          visible ? windowManager.hide() : windowManager.show();
        });
        break;
      case 'exit_app':
        windowManager.destroy();
        break;
      case 'manage_themes':
        // Affiche la fenêtre si elle est cachée, puis navigue
        windowManager.show().then((_) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ThemeManagementScreen(),
            ),
          );
        });
        break;
    }
  }
}
