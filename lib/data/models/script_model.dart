// lib/data/models/script_model.dart
import 'dart:convert';

class ScriptModel {
  // NOUVEAU: Factory pour l'import JSON
  factory ScriptModel.fromJson(Map<String, dynamic> json, int categoryId) {
    return ScriptModel(
      name: json['name'] as String,
      command: json['command'] as String,
      isAdmin: json['isAdmin'] as bool,
      showOutput: json['showOutput'] as bool,
      params: List<String>.from(json['params'] as List<dynamic>? ?? []),
      categoryId: categoryId,
    );
  }
  final int? id;
  final String name;
  final String command;
  final DateTime? lastExecuted;
  final int categoryId;
  final bool isAdmin; // NOUVEAU
  final bool showOutput; // NOUVEAU
  final List<String> params; // NOUVEAU

  ScriptModel({
    this.id,
    required this.name,
    required this.command,
    this.lastExecuted,
    required this.categoryId,
    this.isAdmin = false, // NOUVEAU
    this.showOutput = false, // NOUVEAU
    this.params = const [], // NOUVEAU
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'last_executed': lastExecuted?.toIso8601String(),
      'category_id': categoryId,
      'is_admin': isAdmin ? 1 : 0, // NOUVEAU
      'show_output': showOutput ? 1 : 0, // NOUVEAU
      'params_json': jsonEncode(params), // NOUVEAU
    };
  }

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
      isAdmin: map['is_admin'] == 1, // NOUVEAU
      showOutput: map['show_output'] == 1, // NOUVEAU
      params:
          map['params_json'] !=
                  null // NOUVEAU
              ? List<String>.from(
                jsonDecode(map['params_json'] as String) as List,
              )
              : [],
    );
  }

  // NOUVEAU: Méthode pour l'export JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'command': command,
      'isAdmin': isAdmin,
      'showOutput': showOutput,
      'params': params,
    };
  }
}
