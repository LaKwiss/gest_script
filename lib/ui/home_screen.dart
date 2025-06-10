// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/services/json_service.dart';
import 'package:gest_script/services/script_runner_service.dart';
import 'package:gest_script/ui/widgets/add_category_dialog.dart';
import 'package:gest_script/ui/widgets/add_script_dialog.dart';
import 'package:gest_script/ui/widgets/script_widget.dart';
import 'package:gest_script/ui/widgets/show_color_picker.dart';
import 'package:window_manager/window_manager.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsyncValue = ref.watch(categoryListProvider);
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
                      color: headerColor.withValues(alpha: 0.15),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        backgroundColor: headerColor.withValues(alpha: 0.1),
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
                                  () => showColorPicker(context, ref, category),
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
                                          (script) => ScriptWidget(
                                            script: script,
                                            ref: ref,
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
}

final scriptRunnerServiceProvider = Provider((ref) => ScriptRunnerService());
