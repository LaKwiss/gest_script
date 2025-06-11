// lib/ui/theme_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gest_script/data/providers/app_providers.dart';

class ThemeManagementScreen extends ConsumerWidget {
  const ThemeManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Thèmes')),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Thème Clair (défaut)"),
            leading: const Icon(Icons.wb_sunny_outlined),
            onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
            trailing:
                themeState.activeCustomThemeId == null &&
                        themeState.currentThemeMode == ThemeMode.light
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
          ),
          ListTile(
            title: const Text("Thème Sombre (défaut)"),
            leading: const Icon(Icons.nightlight_outlined),
            onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
            trailing:
                themeState.activeCustomThemeId == null &&
                        themeState.currentThemeMode == ThemeMode.dark
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Thèmes Personnalisés",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (themeState.customThemes.isEmpty)
            const Center(child: Text("Aucun thème personnalisé importé.")),
          ...themeState.customThemes.map((theme) {
            return ListTile(
              title: Text(theme.name),
              leading: Icon(
                theme.brightness == Brightness.dark
                    ? Icons.brightness_3
                    : Icons.brightness_7,
                color: theme.primaryColor,
              ),
              onTap: () => themeNotifier.applyCustomTheme(theme),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (themeState.activeCustomThemeId == theme.id)
                    const Icon(Icons.check, color: Colors.blue),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => themeNotifier.deleteTheme(theme.id!),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Importer"),
              onPressed: () {
                ref.read(themeServiceProvider).importThemes(context);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Exporter"),
              onPressed: () {
                ref.read(themeServiceProvider).exportThemes(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
