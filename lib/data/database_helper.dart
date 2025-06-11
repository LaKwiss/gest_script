// lib/data/database_helper.dart
import 'package:gest_script/data/models/category_model.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/models/theme_model.dart'; // Importer le nouveau modèle
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('launcher.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3, // Augmenter la version de la BDD
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Table existantes
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        color_hex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE scripts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        command TEXT NOT NULL,
        last_executed TEXT,
        category_id INTEGER NOT NULL,
        is_admin INTEGER NOT NULL DEFAULT 0,
        show_output INTEGER NOT NULL DEFAULT 0,
        params_json TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // NOUVELLE TABLE POUR LES THÈMES
    await db.execute('''
      CREATE TABLE themes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brightness INTEGER NOT NULL,
        primaryColor INTEGER NOT NULL,
        backgroundColor INTEGER NOT NULL,
        cardColor INTEGER NOT NULL,
        textColor INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrations existantes...
      await db.execute("ALTER TABLE categories ADD COLUMN color_hex TEXT");
      await db.execute(
        "ALTER TABLE scripts ADD COLUMN is_admin INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE scripts ADD COLUMN show_output INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute("ALTER TABLE scripts ADD COLUMN params_json TEXT");
    }
    if (oldVersion < 3) {
      // NOUVELLE MIGRATION
      await db.execute('''
        CREATE TABLE themes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          brightness INTEGER NOT NULL,
          primaryColor INTEGER NOT NULL,
          backgroundColor INTEGER NOT NULL,
          cardColor INTEGER NOT NULL,
          textColor INTEGER NOT NULL
        )
      ''');
    }
  }

  // --- CRUD pour les thèmes ---

  Future<CustomThemeModel> createTheme(CustomThemeModel theme) async {
    final db = await instance.database;
    final id = await db.insert('themes', theme.toMap());
    return CustomThemeModel(
      id: id,
      name: theme.name,
      brightness: theme.brightness,
      primaryColor: theme.primaryColor,
      backgroundColor: theme.backgroundColor,
      cardColor: theme.cardColor,
      textColor: theme.textColor,
    );
  }

  Future<List<CustomThemeModel>> readAllThemes() async {
    final db = await instance.database;
    final result = await db.query('themes', orderBy: 'name ASC');
    return result.map((json) => CustomThemeModel.fromMap(json)).toList();
  }

  Future<int> deleteTheme(int id) async {
    final db = await instance.database;
    return await db.delete('themes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllThemes() async {
    final db = await instance.database;
    await db.delete('themes');
  }

  // --- Méthodes existantes (inchangées) ---
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final db = await instance.database;
    final id = await db.insert('categories', category.toMap());
    return CategoryModel(
      id: id,
      name: category.name,
      displayOrder: category.displayOrder,
      colorHex: category.colorHex,
    );
  }

  Future<List<CategoryModel>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'display_order ASC');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCategoryColor(int id, String colorHex) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      {'color_hex': colorHex},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ScriptModel>> readAllScripts() async {
    final db = await instance.database;
    final result = await db.query('scripts', orderBy: 'name ASC');
    return result.map((json) => ScriptModel.fromMap(json)).toList();
  }

  Future<List<ScriptModel>> readScriptsByCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.query(
      'scripts',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return result.map((json) => ScriptModel.fromMap(json)).toList();
  }

  Future<ScriptModel> createScript(ScriptModel script) async {
    final db = await instance.database;
    final id = await db.insert('scripts', script.toMap());
    return ScriptModel(
      id: id,
      name: script.name,
      command: script.command,
      categoryId: script.categoryId,
    );
  }

  Future<int> updateScript(ScriptModel script) async {
    final db = await instance.database;
    return await db.update(
      'scripts',
      script.toMap(),
      where: 'id = ?',
      whereArgs: [script.id],
    );
  }

  Future<int> updateScriptLastExecuted(int id) async {
    final db = await instance.database;
    return db.update(
      'scripts',
      {'last_executed': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteScript(int id) async {
    final db = await instance.database;
    return await db.delete('scripts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('scripts');
    await db.delete('categories');
    await db.delete('themes'); // Vider aussi les thèmes
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
