
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalJsonStorage {
  static const String _fileName = 'dreamideaura_data.json';

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<Map<String, dynamic>> readData() async {
    final file = await _getFile();

    if (!await file.exists()) {
      return <String, dynamic>{};
    }

    final contents = await file.readAsString();

    if (contents.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(contents);

    if (decoded is! Map) {
      throw const FormatException('Invalid local storage data.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<void> writeData(Map<String, dynamic> data) async {
    final file = await _getFile();

    await file.writeAsString(
      jsonEncode(data),
      flush: true,
    );
  }

  /// Replaces all stored data.
  ///
  /// A temporary file and rollback copy protect existing data if the
  /// replacement fails.
  Future<void> replaceData(Map<String, dynamic> data) async {
    final file = await _getFile();
    final tempFile = File('${file.path}.tmp');
    final backupFile = File('${file.path}.rollback');

    await tempFile.writeAsString(
      jsonEncode(data),
      flush: true,
    );

    final hadOriginal = await file.exists();

    if (hadOriginal) {
      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      await file.copy(backupFile.path);
      await file.delete();
    }

    try {
      await tempFile.rename(file.path);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (_) {
      if (hadOriginal && await backupFile.exists()) {
        await backupFile.copy(file.path);
      }

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      rethrow;
    }
  }
}
