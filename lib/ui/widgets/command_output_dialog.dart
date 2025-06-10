import 'dart:io';

import 'package:flutter/material.dart';

Future<void> showOutputDialog(
  BuildContext context,
  ProcessResult result,
) async {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text('Sortie du script (Code: ${result.exitCode})'),
          content: SingleChildScrollView(
            child: Text(
              result.stdout.toString().isNotEmpty
                  ? result.stdout.toString()
                  : result.stderr.toString(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
  );
}
