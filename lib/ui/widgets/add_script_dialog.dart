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

  // Controllers for scheduled parameter values
  final Map<String, TextEditingController> _paramValueControllers = {};
  List<String> _parsedParams = [];

  @override
  void initState() {
    super.initState();
    _commandController.addListener(_updateParsedParams);
  }

  void _updateParsedParams() {
    final params =
        RegExp(r'\{(\w+)\}')
            .allMatches(_commandController.text)
            .map((m) => m.group(1)!)
            .toSet()
            .toList();

    // Avoid unnecessary rebuilds if the list hasn't changed
    if (params.toString() != _parsedParams.toString()) {
      setState(() {
        _parsedParams = params;
        // Create new controllers for new params
        for (final param in _parsedParams) {
          if (!_paramValueControllers.containsKey(param)) {
            _paramValueControllers[param] = TextEditingController();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _commandController.removeListener(_updateParsedParams);
    _nameController.dispose();
    _commandController.dispose();
    _paramsController.dispose();
    for (final controller in _paramValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
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

      final String? scheduledTimeString;
      if (_isScheduled) {
        scheduledTimeString =
            '${_scheduledTime.hour.toString().padLeft(2, '0')}: '
            '${_scheduledTime.minute.toString().padLeft(2, '0')}';
      } else {
        scheduledTimeString = null;
      }

      DateTime? nextRun;
      if (_isScheduled) {
        nextRun = calculateNextRunTime(
          scheduledTime: _scheduledTime,
          repeatDays: _repeatDays,
        );
      }

      final scheduledParams = <String, String>{};
      if (_isScheduled) {
        for (final paramName in _parsedParams) {
          scheduledParams[paramName] = _paramValueControllers[paramName]!.text;
        }
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
        scheduledParams: scheduledParams,
      );

      widget.ref
          .read(scriptListProvider(widget.categoryId).notifier)
          .createScript(newScript);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: InputDecoration(
                  labelText: 'Commande',
                  hintText:
                      _isScheduled
                          ? 'ex: python script.py'
                          : 'ex: python script.py {message}',
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
                enabled: _isScheduled == false,
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
                enabled: _isScheduled == false,
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text("Programmer l'exécution"),
                value: _isScheduled,
                onChanged: (val) => setState(() => _isScheduled = val),
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
                        : 'Répéter les jours sélectionnés.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                // Section for parameter values
                if (_parsedParams.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Valeurs pour la planification',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._parsedParams.map((param) {
                    return TextFormField(
                      controller: _paramValueControllers[param],
                      decoration: InputDecoration(
                        labelText: 'Valeur pour {$param}',
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Une valeur est requise pour '
                                      'la planification'
                                  : null,
                    );
                  }),
                ],
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
          onPressed: _onSave,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

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
