// lib/services/scheduling_service.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/providers/app_providers.dart';
import 'package:gest_script/ui/home_screen.dart';
import 'package:gest_script/utils/scheduling_utils.dart';

// Provider for the service, accessible globalement
final schedulingServiceProvider = Provider<SchedulingService>((ref) {
  return SchedulingService(ref);
});

class SchedulingService {
  SchedulingService(this._ref);
  final Ref _ref;
  Timer? _timer;

  /// Initialise le service et démarre le minuteur de vérification.
  void init() {
    _timer?.cancel();
    // On vérifie toutes les minutes.
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkScheduledScripts(),
    );
    log('SchedulingService initialisé.');
    // On lance une première vérification au démarrage.
    _checkScheduledScripts();
  }

  void dispose() {
    _timer?.cancel();
    log('SchedulingService détruit.');
  }

  /// Vérifie la base de données pour les scripts dont l'heure d'exécution est
  /// dépassée.
  Future<void> _checkScheduledScripts() async {
    log('Vérification des scripts programmés...');
    final now = DateTime.now();
    final db = _ref.read(databaseProvider);
    final allScripts = await db.readAllScripts();

    final dueScripts =
        allScripts.where((script) {
          return script.isScheduled &&
              script.nextRunTime != null &&
              (script.nextRunTime!.isBefore(now) ||
                  script.nextRunTime!.isAtSameMomentAs(now));
        }).toList();

    if (dueScripts.isNotEmpty) {
      log('Trouvé ${dueScripts.length} script(s) à exécuter.');
    }

    for (final script in dueScripts) {
      log('Exécution du script programmé : ${script.name}');

      // Prépare la commande en remplaçant les paramètres par leurs valeurs par
      // défaut.
      var commandToRun = script.command;
      if (script.scheduledParams.isNotEmpty) {
        script.scheduledParams.forEach((key, value) {
          commandToRun = commandToRun.replaceAll('{$key}', value);
        });
        log('Commande avec paramètres remplacés : $commandToRun');
      }

      // Exécute la commande finale du script.
      final runner = _ref.read(scriptRunnerServiceProvider);
      await runner.run(commandToRun, runAsAdmin: script.isAdmin);

      // Met à jour la date de dernière exécution.
      await db.updateScriptLastExecuted(script.id!);

      // S'il ne se répète pas, on le désactive.
      if (script.repeatDays.isEmpty) {
        final updatedScript = script.copyWith(
          isScheduled: false,
          setScheduledTimeToNull: true,
          setNextRunTimeToNull: true,
        );
        await db.updateScript(updatedScript);
        log('Script ponctuel désactivé : ${script.name}');
      } else {
        // Sinon, on calcule sa prochaine exécution.
        final parts = script.scheduledTime!.split(':');
        final scheduledTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        final nextRun = calculateNextRunTime(
          scheduledTime: scheduledTime,
          repeatDays: script.repeatDays,
          // On part de l'heure prévue pour éviter les décalages si l'app était
          // fermée.
          from: script.nextRunTime,
        );
        final updatedScript = script.copyWith(nextRunTime: nextRun);
        await db.updateScript(updatedScript);
        log('Script "${script.name}" reprogrammé pour $nextRun');
      }
    }

    // Invalide les providers pour rafraîchir l'UI si elle est visible.
    if (dueScripts.isNotEmpty) {
      _ref.invalidate(allScriptsProvider);
    }
  }
}
