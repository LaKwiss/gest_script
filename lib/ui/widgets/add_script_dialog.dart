// lib/ui/widgets/add_script_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/utils/scheduling_utils.dart';

void showAddScriptDialog(BuildContext context, WidgetRef ref, int categoryId) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return _AddScriptDialogContent(ref: ref, categoryId: categoryId);
    },
  );
}

class _AddScriptDialogContent extends ConsumerStatefulWidget {
  const _AddScriptDialogContent({
    required this.ref,
    required this.categoryId,
  });

  final WidgetRef ref;
  final int categoryId;

  @override
  ConsumerState<_AddScriptDialogContent> createState() =>
      _AddScriptDialogContentState();
}

class _AddScriptDialogContentState
    extends ConsumerState<_AddScriptDialogContent> {
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  final _paramsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  var _isAdmin = false;
  var _showOutput = false;

  // State for scheduling
  var _isScheduled = false;
  var _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
  final List<int> _repeatDays = [];

  final Map<int, String> _weekDays = {
    DateTime.monday: 'Lun',
    DateTime.tuesday: 'Mar',
    DateTime.wednesday: 'Mer',
    DateTime.thursday: 'Jeu',
    DateTime.friday: 'Ven',
    DateTime.saturday: 'Sam',
    DateTime.sunday: 'Dim',
  };

  @override
  void initState() {
    super.initState();
    // Listen to command changes to enable/disable scheduling
    _commandController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _paramsController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null && picked != _scheduledTime) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final params =
          _paramsController.text.isNotEmpty
              ? _paramsController.text.split(',').map((p) => p.trim()).toList()
              : <String>[];

      String? scheduledTimeString =
          _isScheduled
              ? '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}'
              : null;

      DateTime? nextRun;
      if (_isScheduled) {
        nextRun = calculateNextRunTime(
          scheduledTime: _scheduledTime,
          repeatDays: _repeatDays,
        );
      }

      final newScript = ScriptModel(
        name: _nameController.text,
        command: _commandController.text,
        categoryId: widget.categoryId,
        isAdmin: _isAdmin,
        showOutput: _showOutput,
        params: params,
        isScheduled: _isScheduled,
        scheduledTime: scheduledTimeString,
        repeatDays: _isScheduled ? _repeatDays : [],
        nextRunTime: nextRun,
      );

      widget.ref
          .read(scriptListProvider(widget.categoryId).notifier)
          .createScript(newScript);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un script avec des paramètres d'exécution ne peut pas être planifié.
    final bool commandHasParams = _commandController.text.contains('{');

    return AlertDialog(
      title: const Text('Nouveau Script'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nom du script'),
                validator:
                    (value) => value!.isEmpty ? 'Le nom est requis' : null,
              ),
              TextFormField(
                controller: _commandController,
                decoration: const InputDecoration(
                  labelText: 'Commande',
                  hintText: 'ex: git commit -m "{message}"',
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'La commande est requise' : null,
              ),
              TextFormField(
                controller: _paramsController,
                decoration: const InputDecoration(
                  labelText: 'Noms des paramètres (séparés par virgule)',
                  hintText: 'ex: message,auteur',
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text("Exécuter en tant qu'administrateur"),
                value: _isAdmin,
                onChanged: (val) => setState(() => _isAdmin = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Afficher la sortie après exécution'),
                value: _showOutput,
                onChanged: (val) => setState(() => _showOutput = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text("Programmer l'exécution"),
                subtitle:
                    commandHasParams
                        ? const Text(
                          "Indisponible pour les scripts avec paramètres",
                          style: TextStyle(color: Colors.orange),
                        )
                        : null,
                value: _isScheduled,
                onChanged:
                    commandHasParams
                        ? null
                        : (val) => setState(() => _isScheduled = val),
              ),
              if (_isScheduled) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text("Heure d'exécution"),
                  trailing: Text(
                    _scheduledTime.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: _selectTime,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children:
                      _weekDays.entries.map((entry) {
                        return FilterChip(
                          label: Text(entry.value),
                          selected: _repeatDays.contains(entry.key),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _repeatDays.add(entry.key);
                              } else {
                                _repeatDays.remove(entry.key);
                              }
                              _repeatDays.sort();
                            });
                          },
                        );
                      }).toList(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _repeatDays.isEmpty
                        ? "S'exécutera une seule fois."
                        : "Répéter les jours sélectionnés.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
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
          onPressed: _onSave,
        ),
      ],
    );
  }
}

// Le dialogue pour les paramètres reste inchangé
Future<List<String>?> showParamsDialog(
  BuildContext context,
  List<String> params,
) async {
  final controllers = {for (final p in params) p: TextEditingController()};
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
              onPressed: () => Navigator.of(context).pop(),
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
