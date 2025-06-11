// lib/ui/widgets/add_category_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/category_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';

void showAddCategoryDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Nouvelle Catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Ajouter'),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // --- DÉBUT DE LA MODIFICATION ---

                // 1. On récupère la liste actuelle des catégories depuis le
                // provider.
                // Le `.value ?? []` gère le cas où la liste est en cours de
                //chargement ou en erreur.
                final currentCategories =
                    ref.read(categoryListProvider).value ?? [];

                // 2. Le nouvel ordre sera la taille actuelle de la liste.
                // S'il y a 0 catégories, l'ordre sera 0. S'il y en a 3, l'ordre
                // sera 3.
                final newOrder = currentCategories.length;

                // 3. On crée un objet CategoryModel complet avec le nom et le
                //nouvel ordre.
                final newCategory = CategoryModel(
                  name: controller.text,
                  displayOrder: newOrder,
                );

                // 4. On passe l'objet complet au provider.
                ref
                    .read(categoryListProvider.notifier)
                    .addCategory(newCategory);

                // --- FIN DE LA MODIFICATION ---

                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}
