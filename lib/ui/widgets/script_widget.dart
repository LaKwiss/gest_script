import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/services/script_runner_service.dart';
import 'package:gest_script/ui/widgets/edit_script_dialog.dart';

class ScriptWidget extends StatelessWidget {
  const ScriptWidget({
    required this.script,
    required this.ref,
    required this.hexColor,
    super.key,
  });

  final ScriptModel script;
  final WidgetRef ref;
  final Color hexColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.play_arrow, color: hexColor),
      title: Text(script.name),
      subtitle: Text(
        'Dernière exécution: ${script.lastExecuted?.toLocal().toString() ?? 'Jamais'}',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      onTap: () => handleScriptExecution(context, ref, script),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: hexColor, size: 20),
            tooltip: 'Modifier',
            onPressed: () => showEditScriptDialog(context, ref, script),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: hexColor, size: 20),
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
}
