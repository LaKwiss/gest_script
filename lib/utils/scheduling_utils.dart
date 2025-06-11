// lib/utils/scheduling_utils.dart
import 'package:flutter/material.dart';

/// Calcule la prochaine date et heure d'exécution en fonction des paramètres.
///
/// [scheduledTime] est l'heure de la journée (ex: 08:30).
/// [repeatDays] est une liste d'entiers représentant les jours de la semaine
/// (lundi = 1, dimanche = 7).
/// [from] est le point de départ du calcul, par défaut `DateTime.now()`.
DateTime? calculateNextRunTime({
  required TimeOfDay scheduledTime,
  required List<int> repeatDays,
  DateTime? from,
}) {
  final now = from ?? DateTime.now();

  // Si aucun jour de répétition n'est spécifié, il s'agit d'une tâche unique.
  if (repeatDays.isEmpty) {
    var potentialRunTime = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    // Si l'heure d'aujourd'hui est déjà passée, on programme pour demain.
    if (potentialRunTime.isBefore(now)) {
      potentialRunTime = potentialRunTime.add(const Duration(days: 1));
    }
    return potentialRunTime;
  }

  // Si la tâche est récurrente, on cherche le prochain jour valide.
  // On commence par vérifier pour aujourd'hui et les 6 jours suivants.
  for (int i = 0; i < 7; i++) {
    final checkingDate = now.add(Duration(days: i));

    // Vérifie si le jour de la semaine est dans notre liste de répétition.
    if (repeatDays.contains(checkingDate.weekday)) {
      var nextScheduledDateTime = DateTime(
        checkingDate.year,
        checkingDate.month,
        checkingDate.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      // Si on vérifie pour aujourd'hui (i=0), il faut s'assurer que l'heure n'est pas déjà passée.
      if (i == 0 && nextScheduledDateTime.isBefore(now)) {
        continue; // L'heure est passée pour aujourd'hui, on passe au prochain jour valide.
      }

      return nextScheduledDateTime;
    }
  }

  // En théorie, ne devrait pas être atteint si repeatDays n'est pas vide.
  // C'est une sécurité pour trouver le prochain jour la semaine suivante.
  for (int i = 7; i < 14; i++) {
    final checkingDate = now.add(Duration(days: i));
    if (repeatDays.contains(checkingDate.weekday)) {
      return DateTime(
        checkingDate.year,
        checkingDate.month,
        checkingDate.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
    }
  }

  return null; // Fallback
}
