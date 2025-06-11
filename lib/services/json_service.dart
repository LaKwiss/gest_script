// lib/services/json_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/category_model.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';

class JsonService {
  JsonService(this._ref);
  final Ref _ref;

  Future<void> exportJson(BuildContext context) async {
    final categories = _ref.read(categoryListProvider).value ?? [];
    final exportData = <String, dynamic>{
      'version': 1,
      'categories': <Map<String, dynamic>>[],
    };

    for (final cat in categories) {
      final scripts = await _ref
          .read(databaseProvider)
          .readScriptsByCategory(cat.id!);
      (exportData['categories'] as List<Map<String, dynamic>>).add({
        'name': cat.name,
        'colorHex': cat.colorHex,
        'scripts': scripts.map((s) => s.toJson()).toList(),
      });
    }

    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter la configuration',
      fileName: 'gest-script-backup.json',
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(jsonEncode(exportData));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Exportation réussie !')));
      }
    }
  }

  Future<void> importJson(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Importer une configuration'),
            content: const Text(
              'ATTENTION : Ceci remplacera toute votre configuration actuelle. '
              'Voulez-vous continuer ?',
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Remplacer'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content);

      await _ref.read(databaseProvider).clearAllData();

      final categoriesData = (data as Map<String, dynamic>)['categories'];
      var catOrder = 0;
      for (final catData in categoriesData as List<dynamic>) {
        final newCategoryModel = CategoryModel(
          name: (catData as Map<String, dynamic>)['name'] as String,
          displayOrder: catOrder++,
          colorHex: catData['colorHex'] as String,
        );
        final createdCategory = await _ref
            .read(databaseProvider)
            .createCategory(newCategoryModel);

        final scriptsData = List<Map<String, dynamic>>.from(
          catData['scripts'] as List<dynamic>,
        );
        for (final scriptData in scriptsData) {
          final newScript = ScriptModel.fromJson(
            scriptData,
            createdCategory.id!,
          );
          await _ref.read(databaseProvider).createScript(newScript);
        }
      }

      _ref.invalidate(categoryListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Importation réussie !')));
      }
    }
  }
}
