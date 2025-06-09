// lib/services/script_runner_service.dart
import 'dart:io';

class ScriptRunnerService {
  Future<ProcessResult> run(String command, {bool runAsAdmin = false}) async {
    try {
      if (Platform.isWindows) {
        if (runAsAdmin) {
          // Utilise PowerShell pour lancer un processus avec élévation de privilèges
          // Note : Cette méthode ne capture pas stdout/stderr du processus élevé.
          // C'est une limitation de 'Start-Process -Verb RunAs'.
          return await Process.run('powershell', [
            '-Command',
            'Start-Process',
            'cmd',
            '-ArgumentList',
            "'/c, $command & pause'", // 'pause' pour garder la fenêtre visible
            '-Verb',
            'RunAs',
          ], runInShell: true);
        } else {
          return await Process.run('cmd', ['/c', command], runInShell: true);
        }
      } else {
        // Pour macOS ou Linux
        return await Process.run('bash', ['-c', command], runInShell: true);
      }
    } catch (e) {
      print('Erreur lors de l\'exécution du script: $e');
      rethrow;
    }
  }
}
