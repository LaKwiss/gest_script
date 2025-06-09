// lib/ui/widgets/add_script_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';

void showAddScriptDialog(BuildContext context, WidgetRef ref, int categoryId) {
  final nameController = TextEditingController();
  final commandController = TextEditingController();
  final paramsController = TextEditingController(); // Pour les paramètres
  final formKey = GlobalKey<FormState>();

  bool isAdmin = false;
  bool showOutput = false;

  showDialog(
    context: context,
    builder: (context) {
      // On utilise un StatefulWidget pour gérer l'état des Checkbox
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nouveau Script'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                // Pour éviter les soucis de hauteur
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nom du script',
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Le nom est requis' : null,
                    ),
                    TextFormField(
                      controller: commandController,
                      decoration: const InputDecoration(
                        labelText: 'Commande',
                        hintText: 'ex: git commit -m "{message}"',
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'La commande est requise' : null,
                    ),
                    TextFormField(
                      controller: paramsController,
                      decoration: const InputDecoration(
                        labelText: 'Noms des paramètres (séparés par virgule)',
                        hintText: 'ex: message,auteur',
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text("Exécuter en tant qu'administrateur"),
                      value: isAdmin,
                      onChanged: (val) => setState(() => isAdmin = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text("Afficher la sortie après exécution"),
                      value: showOutput,
                      onChanged: (val) => setState(() => showOutput = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Ajouter'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final params =
                        paramsController.text.isNotEmpty
                            ? paramsController.text
                                .split(',')
                                .map((p) => p.trim())
                                .toList()
                            : <String>[];

                    final newScript = ScriptModel(
                      name: nameController.text,
                      command: commandController.text,
                      categoryId: categoryId,
                      isAdmin: isAdmin,
                      showOutput: showOutput,
                      params: params,
                    );

                    // On utilise le provider existant, pas besoin de le changer
                    ref
                        .read(scriptListProvider(categoryId).notifier)
                        .createScript(newScript);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
