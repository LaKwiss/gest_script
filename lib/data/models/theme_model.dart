// lib/data/models/theme_model.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CustomThemeModel {
  final int? id;
  final String name;
  final Brightness brightness;
  final Color primaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;

  CustomThemeModel({
    this.id,
    required this.name,
    required this.brightness,
    required this.primaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
  });

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

  factory CustomThemeModel.fromMap(Map<String, dynamic> map) {
    return CustomThemeModel(
      id: map['id'],
      name: map['name'],
      brightness: Brightness.values[map['brightness']],
      primaryColor: Color(map['primaryColor']),
      backgroundColor: Color(map['backgroundColor']),
      cardColor: Color(map['cardColor']),
      textColor: Color(map['textColor']),
    );
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

  factory CustomThemeModel.fromJson(Map<String, dynamic> json) {
    Color colorFromHex(String hex) {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    }

    return CustomThemeModel(
      name: json['name'],
      brightness:
          json['brightness'] == 'light' ? Brightness.light : Brightness.dark,
      primaryColor: colorFromHex(json['primaryColor']),
      backgroundColor: colorFromHex(json['backgroundColor']),
      cardColor: colorFromHex(json['cardColor']),
      textColor: colorFromHex(json['textColor']),
    );
  }
}
