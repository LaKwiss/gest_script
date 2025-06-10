// lib/services/script_runner_service.dart
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/script_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/ui/home_screen.dart';
import 'package:gest_script/ui/widgets/add_script_dialog.dart';
import 'package:gest_script/ui/widgets/command_output_dialog.dart';

class ScriptRunnerService {
  Future<ProcessResult> run(String command, {bool runAsAdmin = false}) async {
    try {
      if (Platform.isWindows) {
        if (runAsAdmin) {
          // Utilise PowerShell pour lancer un processus avec élévation de privilèges
          // Note : Cette méthode ne capture pas stdout/stderr du processus élevé.
          // C'est une limitation de 'Start-Process -Verb RunAs'.
          return await Process.run('powershell', [
            '-Command',
            'Start-Process',
            'cmd',
            '-ArgumentList',
            "'/c, $command & pause'", // 'pause' pour garder la fenêtre visible
            '-Verb',
            'RunAs',
          ], runInShell: true);
        } else {
          return await Process.run('cmd', ['/c', command], runInShell: true);
        }
      } else {
        // Pour macOS ou Linux
        return await Process.run('bash', ['-c', command], runInShell: true);
      }
    } catch (e) {
      log('Erreur lors de l\'exécution du script: $e');
      rethrow;
    }
  }
}

void handleScriptExecution(
  BuildContext context,
  WidgetRef ref,
  ScriptModel script,
) async {
  final runner = ref.read(scriptRunnerServiceProvider);
  String commandToRun = script.command;
  if (script.params.isNotEmpty) {
    final paramValues = await showParamsDialog(context, script.params);
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
    await showOutputDialog(context, result);
  }
}
