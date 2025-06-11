// lib/data/providers/app_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/database_helper.dart';
import 'package:gest_script/data/models/category_model.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/models/theme_model.dart'; // Importer le modèle de thème
import 'package:gest_script/services/json_service.dart';
import 'package:gest_script/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Thèmes par défaut ---
final defaultLightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  useMaterial3: true,
  cardTheme: const CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
);

final defaultDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFF2D2D2D),
  useMaterial3: true,
  cardTheme: const CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
);

// --- État du thème ---
class ThemeState {
  ThemeState({
    required this.activeThemeData,
    required this.currentThemeMode,
    this.customThemes = const [],
    this.activeCustomThemeId,
  });
  final ThemeData activeThemeData;
  final List<CustomThemeModel> customThemes;
  final int? activeCustomThemeId;
  final ThemeMode currentThemeMode;

  ThemeState copyWith({
    ThemeData? activeThemeData,
    List<CustomThemeModel>? customThemes,
    int? activeCustomThemeId,
    bool clearActiveCustomTheme = false,
    ThemeMode? currentThemeMode,
  }) {
    return ThemeState(
      activeThemeData: activeThemeData ?? this.activeThemeData,
      customThemes: customThemes ?? this.customThemes,
      activeCustomThemeId:
          clearActiveCustomTheme
              ? null
              : activeCustomThemeId ?? this.activeCustomThemeId,
      currentThemeMode: currentThemeMode ?? this.currentThemeMode,
    );
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((
  ref,
) {
  return ThemeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier(this._ref)
    : super(
        ThemeState(
          activeThemeData: defaultDarkTheme,
          currentThemeMode: ThemeMode.dark,
        ),
      ) {
    _loadInitialState();
  }
  final Ref _ref;

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final db = _ref.read(databaseProvider);

    // 1. Charger les thèmes persos
    final customThemes = await db.readAllThemes();

    // 2. Charger les préférences de l'utilisateur
    final themeModeIndex = prefs.getInt('themeMode') ?? ThemeMode.dark.index;
    final activeCustomThemeId = prefs.getInt('activeCustomThemeId');
    final currentThemeMode = ThemeMode.values[themeModeIndex];

    var activeThemeData =
        currentThemeMode == ThemeMode.light
            ? defaultLightTheme
            : defaultDarkTheme;

    // 3. Si un thème perso était actif, on le ré-applique
    if (activeCustomThemeId != null) {
      final activeTheme = customThemes.firstWhere(
        (t) => t.id == activeCustomThemeId,
        orElse: () => customThemes.first,
      );
      activeThemeData = activeTheme.toThemeData();
    }

    state = state.copyWith(
      customThemes: customThemes,
      activeCustomThemeId: activeCustomThemeId,
      activeThemeData: activeThemeData,
      currentThemeMode: currentThemeMode,
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeMode.index);
    await prefs.remove('activeCustomThemeId'); // On enlève le thème perso actif

    state = state.copyWith(
      currentThemeMode: themeMode,
      activeThemeData:
          themeMode == ThemeMode.light ? defaultLightTheme : defaultDarkTheme,
      clearActiveCustomTheme: true,
    );
  }

  Future<void> applyCustomTheme(CustomThemeModel theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeCustomThemeId', theme.id!);

    state = state.copyWith(
      activeThemeData: theme.toThemeData(),
      activeCustomThemeId: theme.id,
      // On met à jour le mode de base pour la cohérence
      currentThemeMode:
          theme.brightness == Brightness.light
              ? ThemeMode.light
              : ThemeMode.dark,
    );
  }

  Future<void> refreshCustomThemes() async {
    final customThemes = await _ref.read(databaseProvider).readAllThemes();
    state = state.copyWith(customThemes: customThemes);
  }

  Future<void> deleteTheme(int themeId) async {
    await _ref.read(databaseProvider).deleteTheme(themeId);
    if (state.activeCustomThemeId == themeId) {
      await setThemeMode(ThemeMode.dark); // Revenir au thème par défaut
    } else {
      await refreshCustomThemes();
    }
  }
}

// --- Le reste des providers (inchangé) ---
final databaseProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

final jsonServiceProvider = Provider<JsonService>((ref) {
  return JsonService(ref);
});

final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService(ref);
});

final allScriptsProvider = FutureProvider<List<ScriptModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.readAllScripts();
});

final categoryListProvider = StateNotifierProvider<
  CategoryListNotifier,
  AsyncValue<List<CategoryModel>>
>((ref) {
  ref.watch(allScriptsProvider);
  return CategoryListNotifier(ref);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final categoriesAsync = ref.watch(categoryListProvider);
  final scriptsAsync = ref.watch(allScriptsProvider);

  if (categoriesAsync is! AsyncData || scriptsAsync is! AsyncData) {
    return [];
  }

  final allCategories = categoriesAsync.value!;
  final allScripts = scriptsAsync.value!;

  if (searchQuery.isEmpty) {
    return allCategories;
  }

  final matchingCategoryIds =
      allScripts
          .where(
            (s) => s.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .map((s) => s.categoryId)
          .toSet();

  return allCategories
      .where((c) => matchingCategoryIds.contains(c.id))
      .toList();
});

class CategoryListNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  CategoryListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _fetchCategories();
  }
  final Ref _ref;

  Future<void> _fetchCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _ref.read(databaseProvider).readAllCategories();
      if (mounted) {
        state = AsyncValue.data(categories);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    await _ref.read(databaseProvider).createCategory(category);
    await _fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _ref.read(databaseProvider).deleteCategory(id);
    await _fetchCategories();
  }

  Future<void> updateCategoryColor(int categoryId, Color color) async {
    // Remplacement de .value par la méthode explicite .toARGB32()
    final colorValue = color.toARGB32();

    // Le reste du code est identique
    final colorHex = colorValue.toRadixString(16).substring(2);
    await _ref.read(databaseProvider).updateCategoryColor(categoryId, colorHex);
    await _fetchCategories();
  }
}

final StateNotifierProviderFamily<
  ScriptListNotifier,
  AsyncValue<List<ScriptModel>>,
  int
>
scriptListProvider = StateNotifierProvider.family<
  ScriptListNotifier,
  AsyncValue<List<ScriptModel>>,
  int
>((ref, categoryId) {
  ref.watch(allScriptsProvider);
  return ScriptListNotifier(ref, categoryId);
});

class ScriptListNotifier extends StateNotifier<AsyncValue<List<ScriptModel>>> {
  ScriptListNotifier(this._ref, this._categoryId)
    : super(const AsyncValue.loading()) {
    _fetchScripts();
  }
  final Ref _ref;
  final int _categoryId;

  Future<void> _fetchScripts() async {
    state = const AsyncValue.loading();
    try {
      final scripts = await _ref
          .read(databaseProvider)
          .readScriptsByCategory(_categoryId);
      if (mounted) {
        state = AsyncValue.data(scripts);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  Future<void> _refreshAllScripts() async {
    _ref.invalidate(allScriptsProvider);
  }

  Future<void> createScript(ScriptModel script) async {
    await _ref.read(databaseProvider).createScript(script);
    await _refreshAllScripts();
  }

  Future<void> editScript(ScriptModel scriptToSave) async {
    await _ref.read(databaseProvider).updateScript(scriptToSave);
    await _refreshAllScripts();
  }

  Future<void> deleteScript(int scriptId) async {
    await _ref.read(databaseProvider).deleteScript(scriptId);
    await _refreshAllScripts();
  }

  Future<void> updateLastExecuted(int scriptId) async {
    await _ref.read(databaseProvider).updateScriptLastExecuted(scriptId);
    await _refreshAllScripts();
  }
}

final Provider<GlobalKey<NavigatorState>> navigatorKeyProvider = Provider(
  (ref) => GlobalKey<NavigatorState>(),
);

final localeNotifierProvider = StateNotifierProvider<LocaleNotifier, Locale>((
  ref,
) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'fr';
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }
}
