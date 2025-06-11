// lib/data/models/script_model.dart
import 'dart:convert';

class ScriptModel {
  ScriptModel({
    required this.name,
    required this.command,
    required this.categoryId,
    this.lastExecuted,
    this.id,
    this.isAdmin = false,
    this.showOutput = false,
    this.params = const [],
    // Nouveaux champs pour la planification
    this.isScheduled = false,
    this.scheduledTime, // ex: "08:30"
    this.repeatDays = const [], // ex: [1, 2, 3, 4, 5] pour Lun-Ven
    this.nextRunTime,
  });

  factory ScriptModel.fromMap(Map<String, dynamic> map) {
    return ScriptModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      command: map['command'] as String,
      lastExecuted:
          map['last_executed'] != null
              ? DateTime.parse(map['last_executed'] as String)
              : null,
      categoryId: map['category_id'] as int,
      isAdmin: map['is_admin'] == 1,
      showOutput: map['show_output'] == 1,
      params:
          map['params_json'] != null
              ? List<String>.from(
                jsonDecode(map['params_json'] as String) as List,
              )
              : [],
      // Nouveaux champs
      isScheduled: map['is_scheduled'] == 1,
      scheduledTime: map['scheduled_time'] as String?,
      repeatDays:
          map['repeat_days_json'] != null
              ? List<int>.from(
                jsonDecode(map['repeat_days_json'] as String) as List,
              )
              : [],
      nextRunTime:
          map['next_run_time'] != null
              ? DateTime.parse(map['next_run_time'] as String)
              : null,
    );
  }

  factory ScriptModel.fromJson(Map<String, dynamic> json, int categoryId) {
    return ScriptModel(
      name: json['name'] as String,
      command: json['command'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
      showOutput: json['showOutput'] as bool? ?? false,
      params: List<String>.from(json['params'] as List<dynamic>? ?? []),
      categoryId: categoryId,
      // La planification n'est pas incluse dans l'import/export JSON
    );
  }

  final int? id;
  final String name;
  final String command;
  final DateTime? lastExecuted;
  final int categoryId;
  final bool isAdmin;
  final bool showOutput;
  final List<String> params;

  // Nouveaux champs
  final bool isScheduled;
  final String? scheduledTime; // "HH:mm"
  final List<int> repeatDays;
  final DateTime? nextRunTime;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'last_executed': lastExecuted?.toIso8601String(),
      'category_id': categoryId,
      'is_admin': isAdmin ? 1 : 0,
      'show_output': showOutput ? 1 : 0,
      'params_json': jsonEncode(params),
      // Nouveaux champs
      'is_scheduled': isScheduled ? 1 : 0,
      'scheduled_time': scheduledTime,
      'repeat_days_json': jsonEncode(repeatDays),
      'next_run_time': nextRunTime?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'command': command,
      'isAdmin': isAdmin,
      'showOutput': showOutput,
      'params': params,
    };
  }

  ScriptModel copyWith({
    int? id,
    String? name,
    String? command,
    DateTime? lastExecuted,
    int? categoryId,
    bool? isAdmin,
    bool? showOutput,
    List<String>? params,
    bool? isScheduled,
    String? scheduledTime,
    List<int>? repeatDays,
    DateTime? nextRunTime,
    bool setScheduledTimeToNull = false,
    bool setNextRunTimeToNull = false,
  }) {
    return ScriptModel(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      categoryId: categoryId ?? this.categoryId,
      isAdmin: isAdmin ?? this.isAdmin,
      showOutput: showOutput ?? this.showOutput,
      params: params ?? this.params,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledTime:
          setScheduledTimeToNull ? null : (scheduledTime ?? this.scheduledTime),
      repeatDays: repeatDays ?? this.repeatDays,
      nextRunTime:
          setNextRunTimeToNull ? null : (nextRunTime ?? this.nextRunTime),
    );
  }
}
