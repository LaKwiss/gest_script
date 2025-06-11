// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/services/script_runner_service.dart';
import 'package:gest_script/ui/theme_managment_screen.dart';
import 'package:gest_script/ui/widgets/add_category_dialog.dart';
import 'package:gest_script/ui/widgets/add_script_dialog.dart';
import 'package:gest_script/ui/widgets/script_widget.dart';
import 'package:gest_script/ui/widgets/show_color_picker.dart';
import 'package:window_manager/window_manager.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (le début du build reste identique)

    return Scaffold(
      body: Column(
        children: [
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
                    'Gest-Script',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Options',
                    onSelected: (value) {
                      if (value == 'import_config') {
                        ref.read(jsonServiceProvider).importJson(context);
                      }
                      if (value == 'export_config') {
                        ref.read(jsonServiceProvider).exportJson(context);
                      }
                      // NOUVEAU : Naviguer vers l'écran de gestion des thèmes
                      if (value == 'manage_themes') {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const ThemeManagementScreen(),
                          ),
                        );
                      }
                    },
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'import_config',
                            child: Text('Importer une configuration'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'export_config',
                            child: Text('Exporter la configuration'),
                          ),
                          const PopupMenuDivider(),
                          // NOUVEAU BOUTON DE MENU
                          const PopupMenuItem<String>(
                            value: 'manage_themes',
                            child: Text('Gérer les thèmes'),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ),
          // ... (le reste du body reste identique)
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
            child: ref
                .watch(categoryListProvider)
                .when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Erreur: $err')),
                  data: (categories) {
                    final filteredCategories = ref.watch(
                      filteredCategoriesProvider,
                    );
                    if (filteredCategories.isEmpty) {
                      return Center(
                        child: Text(
                          ref.watch(searchQueryProvider).isEmpty
                              ? 'Aucune catégorie. Ajoutez-en une !'
                              : 'Aucune catégorie ne correspond à votre '
                                  'recherche.',
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
                                : Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(50);
                        final scriptsAsyncValue = ref.watch(
                          scriptListProvider(category.id!),
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: headerColor.withValues(alpha: 0.15),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            iconColor:
                                category.colorHex != null
                                    ? headerColor
                                    : Colors.grey,

                            collapsedIconColor:
                                category.colorHex != null
                                    ? headerColor
                                    : Colors.grey,

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
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.color_lens_outlined,
                                    size: 20,
                                    color:
                                        category.colorHex != null
                                            ? headerColor
                                            : Colors.grey,
                                  ),
                                  tooltip: 'Changer la couleur',
                                  onPressed:
                                      () => showColorPicker(
                                        context,
                                        ref,
                                        category,
                                      ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    size: 20,
                                    color:
                                        category.colorHex != null
                                            ? headerColor
                                            : Colors.grey,
                                  ),
                                  tooltip: 'Ajouter un script',
                                  onPressed:
                                      () => showAddScriptDialog(
                                        context,
                                        ref,
                                        category.id!,
                                      ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color:
                                        category.colorHex != null
                                            ? headerColor
                                            : Colors.grey,
                                  ),
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
                                      title: Text('Chargement...'),
                                    ),
                                error:
                                    (err, stack) => ListTile(
                                      title: Text('Erreur scripts: $err'),
                                    ),
                                data: (scripts) {
                                  final scriptsToShow =
                                      scripts
                                          .where(
                                            (s) =>
                                                ref
                                                    .watch(searchQueryProvider)
                                                    .isEmpty ||
                                                s.name.toLowerCase().contains(
                                                  ref
                                                      .watch(
                                                        searchQueryProvider,
                                                      )
                                                      .toLowerCase(),
                                                ),
                                          )
                                          .toList();
                                  if (scriptsToShow.isEmpty) {
                                    return const ListTile(
                                      title: Text('Aucun script trouvé.'),
                                    );
                                  }

                                  return Column(
                                    children:
                                        scriptsToShow
                                            .map(
                                              (script) => ScriptWidget(
                                                script: script,
                                                ref: ref,
                                                hexColor:
                                                    category.colorHex != null
                                                        ? headerColor
                                                        : Colors.red,
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

final Provider<ScriptRunnerService> scriptRunnerServiceProvider = Provider(
  (ref) => ScriptRunnerService(),
);
