import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/models/category_model.dart';
import 'package:gest_script/data/providers/app_providers.dart';

Future<void> showColorPicker(
  BuildContext context,
  WidgetRef ref,
  CategoryModel category,
) async {
  Color pickerColor =
      category.colorHex != null
          ? Color(int.parse('0xFF${category.colorHex!}'))
          : Colors.blue;
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Choisir une couleur'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Valider'),
              onPressed: () {
                ref
                    .read(categoryListProvider.notifier)
                    .updateCategoryColor(category.id!, pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
  );
}
