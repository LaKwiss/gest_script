// lib/ui/widgets/edit_script_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';

void showEditScriptDialog(
  BuildContext context,
  WidgetRef ref,
  ScriptModel script,
) {
  // Pré-remplissage des contrôleurs avec les données du script existant
  final nameController = TextEditingController(text: script.name);
  final commandController = TextEditingController(text: script.command);
  final paramsController = TextEditingController(
    text: script.params.join(', '),
  );
  final formKey = GlobalKey<FormState>();

  // Pré-remplissage des booléens
  var isAdmin = script.isAdmin;
  var showOutput = script.showOutput;

  showDialog<void>(
    context: context,
    builder: (context) {
      // On utilise StatefulBuilder pour que les Checkbox puissent se redessiner
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Modifier le Script'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
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
                      title: const Text('Afficher la sortie après exécution'),
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
                child: const Text('Enregistrer'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final params =
                        paramsController.text.isNotEmpty
                            ? paramsController.text
                                .split(',')
                                .map((p) => p.trim())
                                .toList()
                            : <String>[];

                    // On crée un nouvel objet ScriptModel avec TOUTES les
                    // données à jour
                    final updatedScript = ScriptModel(
                      id: script.id,
                      name: nameController.text,
                      command: commandController.text,
                      categoryId: script.categoryId,
                      lastExecuted:
                          script
                              .lastExecuted, // On préserve la date d'exécution
                      isAdmin: isAdmin,
                      showOutput: showOutput,
                      params: params,
                    );

                    // On appelle la méthode du provider avec l'objet complet
                    ref
                        .read(scriptListProvider(script.categoryId).notifier)
                        .editScript(updatedScript);
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
