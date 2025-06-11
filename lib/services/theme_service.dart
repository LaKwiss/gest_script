// lib/services/theme_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/theme_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';

class ThemeService {
  final Ref _ref;
  ThemeService(this._ref);

  Future<void> exportThemes(BuildContext context) async {
    final db = _ref.read(databaseProvider);
    final themes = await db.readAllThemes();
    if (themes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun thème personnalisé à exporter.')),
        );
      }
      return;
    }

    final List<Map<String, dynamic>> exportData =
        themes.map((t) => t.toJson()).toList();

    final String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter les thèmes',
      fileName: 'gest-script-themes.json',
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(jsonEncode(exportData));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thèmes exportés avec succès !')),
        );
      }
    }
  }

  Future<void> importThemes(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Importer des thèmes'),
            content: const Text(
              'Ceci remplacera vos thèmes personnalisés existants. Continuer ?',
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

      // ##### DÉBUT DE LA VALIDATION #####

      // 1. Vérifier si le fichier est vide
      if (content.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur : Le fichier est vide.')),
          );
        }
        return;
      }

      try {
        final List<dynamic> data = jsonDecode(content);

        final db = _ref.read(databaseProvider);
        await db.clearAllThemes();

        for (var themeJson in data) {
          // La conversion ici peut échouer si la structure est mauvaise.
          // Le `try...catch` l'interceptera.
          final theme = CustomThemeModel.fromJson(themeJson);
          await db.createTheme(theme);
        }

        await _ref.read(themeNotifierProvider.notifier).refreshCustomThemes();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thèmes importés avec succès !')),
          );
        }
      } catch (e) {
        // 2. Intercepter toute erreur de format ou de structure
        debugPrint("Erreur d'importation de thème : $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur : Le format du fichier est invalide.'),
            ),
          );
        }
      }
    }
  }
}
