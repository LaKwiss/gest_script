// lib/data/models/script_model.dart
import 'dart:convert';

class ScriptModel {
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
      id: map['id'],
      name: map['name'],
      command: map['command'],
      lastExecuted:
          map['last_executed'] != null
              ? DateTime.parse(map['last_executed'])
              : null,
      categoryId: map['category_id'],
      isAdmin: map['is_admin'] == 1, // NOUVEAU
      showOutput: map['show_output'] == 1, // NOUVEAU
      params:
          map['params_json'] !=
                  null // NOUVEAU
              ? List<String>.from(jsonDecode(map['params_json']))
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

  // NOUVEAU: Factory pour l'import JSON
  factory ScriptModel.fromJson(Map<String, dynamic> json, int categoryId) {
    return ScriptModel(
      name: json['name'],
      command: json['command'],
      isAdmin: json['isAdmin'] ?? false,
      showOutput: json['showOutput'] ?? false,
      params: List<String>.from(json['params'] ?? []),
      categoryId: categoryId,
    );
  }
}
