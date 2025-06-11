// lib/ui/widgets/edit_script_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/utils/scheduling_utils.dart';

void showEditScriptDialog(
  BuildContext context,
  WidgetRef ref,
  ScriptModel script,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return _EditScriptDialogContent(ref: ref, script: script);
    },
  );
}

class _EditScriptDialogContent extends ConsumerStatefulWidget {
  const _EditScriptDialogContent({required this.ref, required this.script});

  final WidgetRef ref;
  final ScriptModel script;

  @override
  ConsumerState<_EditScriptDialogContent> createState() =>
      _EditScriptDialogContentState();
}

class _EditScriptDialogContentState
    extends ConsumerState<_EditScriptDialogContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _commandController;
  late final TextEditingController _paramsController;
  final _formKey = GlobalKey<FormState>();

  late bool _isAdmin;
  late bool _showOutput;

  // State for scheduling
  late bool _isScheduled;
  late TimeOfDay _scheduledTime;
  late List<int> _repeatDays;
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
    final script = widget.script;
    _nameController = TextEditingController(text: script.name);
    _commandController = TextEditingController(text: script.command);
    _paramsController = TextEditingController(text: script.params.join(', '));
    _isAdmin = script.isAdmin;
    _showOutput = script.showOutput;

    _isScheduled = script.isScheduled;
    _repeatDays = List.from(script.repeatDays);
    if (script.scheduledTime != null) {
      final parts = script.scheduledTime!.split(':');
      _scheduledTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
    }

    _commandController.addListener(_updateParsedParams);
    _updateParsedParams(initialize: true);
  }

  void _updateParsedParams({bool initialize = false}) {
    final params =
        RegExp(r'\{(\w+)\}')
            .allMatches(_commandController.text)
            .map((m) => m.group(1)!)
            .toSet()
            .toList();

    if (params.toString() != _parsedParams.toString()) {
      setState(() {
        _parsedParams = params;
        for (final param in _parsedParams) {
          if (!_paramValueControllers.containsKey(param)) {
            final initialValue =
                initialize ? widget.script.scheduledParams[param] ?? '' : '';
            _paramValueControllers[param] = TextEditingController(
              text: initialValue,
            );
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
            '${_scheduledTime.hour.toString().padLeft(2, '0')} '
            ':${_scheduledTime.minute.toString().padLeft(2, '0')}';
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

      final updatedScript = widget.script.copyWith(
        name: _nameController.text,
        command: _commandController.text,
        isAdmin: _isAdmin,
        showOutput: _showOutput,
        params: params,
        isScheduled: _isScheduled,
        scheduledTime: scheduledTimeString,
        repeatDays: _isScheduled ? _repeatDays : [],
        nextRunTime: nextRun,
        scheduledParams: scheduledParams,
        setNextRunTimeToNull: !_isScheduled,
        setScheduledTimeToNull: !_isScheduled,
      );

      widget.ref
          .read(scriptListProvider(widget.script.categoryId).notifier)
          .editScript(updatedScript);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le Script'),
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
                        final dayIndex = entry.key;
                        final dayName = entry.value;
                        return FilterChip(
                          label: Text(dayName),
                          selected: _repeatDays.contains(dayIndex),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _repeatDays.add(dayIndex);
                              } else {
                                _repeatDays.remove(dayIndex);
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
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
