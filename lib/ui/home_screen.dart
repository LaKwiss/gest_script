// lib/ui/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/category_model.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/services/json_service.dart';
import 'package:gest_script/services/script_runner_service.dart';
import 'package:gest_script/ui/widgets/add_category_dialog.dart';
import 'package:gest_script/ui/widgets/add_script_dialog.dart';
import 'package:gest_script/ui/widgets/edit_script_dialog.dart';
import 'package:window_manager/window_manager.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On observe l'état de chargement/erreur du provider principal
    final categoriesAsyncValue = ref.watch(categoryListProvider);
    // On récupère la liste déjà filtrée pour l'affichage
    final filteredCategories = ref.watch(filteredCategoriesProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      body: Column(
        children: [
          // Barre de titre
          GestureDetector(
            onPanStart: (details) => windowManager.startDragging(),
            child: Container(
              height: 40,
              color: Colors.black26,
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Spacer(),
                  const Text(
                    "Gest-Script",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Options',
                    onSelected: (value) {
                      if (value == 'import') {
                        JsonService.importJson(context, ref);
                      }
                      if (value == 'export') {
                        JsonService.exportJson(context, ref);
                      }
                    },
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'import',
                            child: Text('Importer une configuration'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'export',
                            child: Text('Exporter la configuration'),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ),
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              onChanged:
                  (value) =>
                      ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Rechercher un script...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: categoriesAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur: $err')),
              // Le `when` est juste pour l'état global, on utilise la liste filtrée pour construire l'UI
              data: (_) {
                if (filteredCategories.isEmpty) {
                  return Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? "Aucune catégorie. Ajoutez-en une !"
                          : "Aucune catégorie ne correspond à votre recherche.",
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    final headerColor =
                        category.colorHex != null
                            ? Color(int.parse('0xFF${category.colorHex!}'))
                            : Colors.transparent;
                    final scriptsAsyncValue = ref.watch(
                      scriptListProvider(category.id!),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: headerColor.withOpacity(0.15),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        backgroundColor: headerColor.withOpacity(0.1),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.color_lens_outlined,
                                size: 20,
                                color:
                                    headerColor != Colors.transparent
                                        ? headerColor
                                        : Colors.grey,
                              ),
                              tooltip: 'Changer la couleur',
                              onPressed:
                                  () =>
                                      _showColorPicker(context, ref, category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              tooltip: 'Ajouter un script',
                              onPressed:
                                  () => showAddScriptDialog(
                                    context,
                                    ref,
                                    category.id!,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Supprimer la catégorie',
                              onPressed:
                                  () => ref
                                      .read(categoryListProvider.notifier)
                                      .deleteCategory(category.id!),
                            ),
                          ],
                        ),
                        children: [
                          scriptsAsyncValue.when(
                            loading:
                                () => const ListTile(
                                  title: Text("Chargement..."),
                                ),
                            error:
                                (err, stack) => ListTile(
                                  title: Text('Erreur scripts: $err'),
                                ),
                            data: (scripts) {
                              // On filtre aussi ici pour n'afficher que les bons scripts dans la catégorie
                              final scriptsToShow =
                                  scripts
                                      .where(
                                        (s) =>
                                            searchQuery.isEmpty ||
                                            s.name.toLowerCase().contains(
                                              searchQuery.toLowerCase(),
                                            ),
                                      )
                                      .toList();
                              if (scriptsToShow.isEmpty) {
                                return const ListTile(
                                  title: Text("Aucun script trouvé."),
                                );
                              }

                              return Column(
                                children:
                                    scriptsToShow
                                        .map(
                                          (script) => _buildScriptTile(
                                            context,
                                            ref,
                                            script,
                                          ),
                                        )
                                        .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddCategoryDialog(context, ref),
        tooltip: 'Ajouter une catégorie',
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }

  Widget _buildScriptTile(
    BuildContext context,
    WidgetRef ref,
    ScriptModel script,
  ) {
    return ListTile(
      leading: const Icon(Icons.play_arrow, color: Colors.blueAccent),
      title: Text(script.name),
      subtitle: Text(
        'Dernière exécution: ${script.lastExecuted?.toLocal().toString() ?? "Jamais"}',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      onTap: () => _handleScriptExecution(context, ref, script),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            tooltip: 'Modifier',
            onPressed: () => showEditScriptDialog(context, ref, script),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
            tooltip: 'Supprimer',
            onPressed:
                () => ref
                    .read(scriptListProvider(script.categoryId).notifier)
                    .deleteScript(script.id!),
          ),
        ],
      ),
    );
  }

  void _handleScriptExecution(
    BuildContext context,
    WidgetRef ref,
    ScriptModel script,
  ) async {
    final runner = ref.read(scriptRunnerServiceProvider);
    String commandToRun = script.command;
    if (script.params.isNotEmpty) {
      final paramValues = await _showParamsDialog(context, script.params);
      if (paramValues == null) return;
      for (var i = 0; i < script.params.length; i++) {
        commandToRun = commandToRun.replaceAll(
          '{${script.params[i]}}',
          paramValues[i],
        );
      }
    }
    final result = await runner.run(commandToRun, runAsAdmin: script.isAdmin);
    ref
        .read(scriptListProvider(script.categoryId).notifier)
        .updateLastExecuted(script.id!);
    if (script.showOutput && context.mounted) {
      await _showOutputDialog(context, result);
    }
  }

  Future<void> _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    Color pickerColor =
        category.colorHex != null
            ? Color(int.parse('0xFF${category.colorHex!}'))
            : Colors.blue;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choisir une couleur'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) => pickerColor = color,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Valider'),
                onPressed: () {
                  ref
                      .read(categoryListProvider.notifier)
                      .updateCategoryColor(category.id!, pickerColor);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  Future<List<String>?> _showParamsDialog(
    BuildContext context,
    List<String> params,
  ) async {
    final controllers = {for (var p in params) p: TextEditingController()};
    final formKey = GlobalKey<FormState>();
    return showDialog<List<String>?>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Entrer les paramètres'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      params
                          .map(
                            (p) => TextFormField(
                              controller: controllers[p],
                              decoration: InputDecoration(labelText: p),
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Ce champ est requis'
                                          : null,
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.of(context).pop(null),
              ),
              TextButton(
                child: const Text('Lancer'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(
                      context,
                    ).pop(params.map((p) => controllers[p]!.text).toList());
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _showOutputDialog(
    BuildContext context,
    ProcessResult result,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sortie du script (Code: ${result.exitCode})'),
            content: SingleChildScrollView(
              child: Text(
                result.stdout.toString().isNotEmpty
                    ? result.stdout.toString()
                    : result.stderr.toString(),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Fermer'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }
}

final scriptRunnerServiceProvider = Provider((ref) => ScriptRunnerService());


//TODO: Segmenter le code en plusieurs fichiers pour une meilleure lisibilité