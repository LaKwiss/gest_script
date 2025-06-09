// lib/data/providers/app_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/database_helper.dart';
import 'package:gest_script/data/models/category_model.dart';
import 'package:gest_script/data/models/script_model.dart';

final databaseProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

// Provider pour charger TOUS les scripts une seule fois
final allScriptsProvider = FutureProvider<List<ScriptModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.readAllScripts();
});

// Le provider des catégories reste un StateNotifierProvider pour garder ses méthodes.
final categoryListProvider = StateNotifierProvider<
  CategoryListNotifier,
  AsyncValue<List<CategoryModel>>
>((ref) {
  // On écoute `allScriptsProvider` pour invalider et donc rafraîchir
  // les catégories si un script est ajouté/modifié/supprimé.
  ref.watch(allScriptsProvider);
  return CategoryListNotifier(ref);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

// filteredCategoriesProvider est maintenant un Provider SYNCHRONE qui dépend des autres.
final filteredCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  // On écoute la recherche, la liste des catégories, et la liste de tous les scripts
  final searchQuery = ref.watch(searchQueryProvider);
  final categoriesAsync = ref.watch(categoryListProvider);
  final scriptsAsync = ref.watch(allScriptsProvider);

  // Si une des sources de données n'est pas prête, on retourne une liste vide.
  // L'UI principale gérera l'affichage du chargement.
  if (categoriesAsync is! AsyncData || scriptsAsync is! AsyncData) {
    return [];
  }

  final allCategories = categoriesAsync.value!;
  final allScripts = scriptsAsync.value!;

  // Si la recherche est vide, on retourne toutes les catégories
  if (searchQuery.isEmpty) {
    return allCategories;
  }

  // On crée un ensemble (Set) des ID de catégories qui ont des scripts correspondants.
  // C'est très performant.
  final matchingCategoryIds =
      allScripts
          .where(
            (s) => s.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .map((s) => s.categoryId)
          .toSet();

  // On filtre la liste des catégories pour ne garder que celles dont l'ID est dans notre ensemble.
  return allCategories
      .where((c) => matchingCategoryIds.contains(c.id))
      .toList();
});

class CategoryListNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final Ref _ref;

  CategoryListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _ref.read(databaseProvider).readAllCategories();
      state = AsyncValue.data(categories);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    await _ref.read(databaseProvider).createCategory(category);
    _fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _ref.read(databaseProvider).deleteCategory(id);
    _fetchCategories();
  }

  Future<void> updateCategoryColor(int categoryId, Color color) async {
    final colorHex = color.value.toRadixString(16).substring(2);
    await _ref.read(databaseProvider).updateCategoryColor(categoryId, colorHex);
    _fetchCategories();
  }
}

final scriptListProvider = StateNotifierProvider.family<
  ScriptListNotifier,
  AsyncValue<List<ScriptModel>>,
  int
>((ref, categoryId) {
  // Le provider par famille est toujours utile pour rafraîchir une seule catégorie
  ref.watch(allScriptsProvider);
  return ScriptListNotifier(ref, categoryId);
});

class ScriptListNotifier extends StateNotifier<AsyncValue<List<ScriptModel>>> {
  final Ref _ref;
  final int _categoryId;

  ScriptListNotifier(this._ref, this._categoryId)
    : super(const AsyncValue.loading()) {
    _fetchScripts();
  }

  Future<void> _fetchScripts() async {
    state = const AsyncValue.loading();
    try {
      final scripts = await _ref
          .read(databaseProvider)
          .readScriptsByCategory(_categoryId);
      state = AsyncValue.data(scripts);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // Ces méthodes doivent maintenant invalider `allScriptsProvider` pour que
  // toute l'application se mette à jour.
  Future<void> _refreshAllScripts() async {
    _ref.invalidate(allScriptsProvider);
  }

  Future<void> createScript(ScriptModel script) async {
    await _ref.read(databaseProvider).createScript(script);
    _refreshAllScripts();
  }

  Future<void> editScript(ScriptModel scriptToSave) async {
    await _ref.read(databaseProvider).updateScript(scriptToSave);
    _refreshAllScripts();
  }

  Future<void> deleteScript(int scriptId) async {
    await _ref.read(databaseProvider).deleteScript(scriptId);
    _refreshAllScripts();
  }

  Future<void> updateLastExecuted(int scriptId) async {
    await _ref.read(databaseProvider).updateScriptLastExecuted(scriptId);
    _refreshAllScripts();
  }
}
