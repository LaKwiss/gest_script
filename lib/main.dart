// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/ui/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // <--- 1. IMPORTEZ LE PAQUET
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  // Assurer l'initialisation des bindings Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // ---> 2. AJOUTEZ CE BLOC D'INITIALISATION POUR SQFLITE SUR DESKTOP <---
  // On vérifie si on est sur une plateforme desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // On initialise le backend FFI
    sqfliteFfiInit();
    // On change la factory de base de données par défaut pour utiliser celle de FFI
    databaseFactory = databaseFactoryFfi;
  }
  // --- FIN DU BLOC AJOUTÉ ---

  // Configuration du gestionnaire de fenêtre
  await windowManager.ensureInitialized();

  // Configuration de la fenêtre au démarrage
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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TrayListener {
  @override
  void initState() {
    super.initState();
    _initTray();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon('assets/app_icon.ico');
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Ouvrir'),
        MenuItem.separator(),
        MenuItem(key: 'quit_app', label: 'Quitter'),
      ],
    );
    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        break;
      case 'quit_app':
        windowManager.destroy();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF2D2D2D),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
