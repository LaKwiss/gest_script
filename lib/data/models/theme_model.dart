// lib/data/models/theme_model.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CustomThemeModel {
  CustomThemeModel({
    required this.name,
    required this.brightness,
    required this.primaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    this.id,
  });
  factory CustomThemeModel.fromJson(Map<String, dynamic> json) {
    Color colorFromHex(String hex) {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    }

    return CustomThemeModel(
      name: json['name'] as String,
      brightness:
          json['brightness'] == 'light' ? Brightness.light : Brightness.dark,
      primaryColor: colorFromHex(json['primaryColor'] as String),
      backgroundColor: colorFromHex(json['backgroundColor'] as String),
      cardColor: colorFromHex(json['cardColor'] as String),
      textColor: colorFromHex(json['textColor'] as String),
    );
  }
  factory CustomThemeModel.fromMap(Map<String, dynamic> map) {
    return CustomThemeModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      brightness: Brightness.values[map['brightness'] as int],
      primaryColor: Color(map['primaryColor'] as int),
      backgroundColor: Color(map['backgroundColor'] as int),
      cardColor: Color(map['cardColor'] as int),
      textColor: Color(map['textColor'] as int),
    );
  }
  final int? id;
  final String name;
  final Brightness brightness;
  final Color primaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;

  ThemeData toThemeData() {
    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
      ),
      useMaterial3: true,
    );
  }

  // Pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brightness': brightness.index,
      'primaryColor': primaryColor.value,
      'backgroundColor': backgroundColor.value,
      'cardColor': cardColor.value,
      'textColor': textColor.value,
    };
  }

  // Pour l'import/export JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brightness': brightness.name, // 'light' ou 'dark'
      'primaryColor': '#${primaryColor.value.toRadixString(16)}',
      'backgroundColor': '#${backgroundColor.value.toRadixString(16)}',
      'cardColor': '#${cardColor.value.toRadixString(16)}',
      'textColor': '#${textColor.value.toRadixString(16)}',
    };
  }
}
