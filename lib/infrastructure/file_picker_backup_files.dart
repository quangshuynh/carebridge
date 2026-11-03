import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/board_backup.dart';
import '../services/backup_files.dart';

/// Saves and opens backups with the platform's own document dialogs (the
/// Storage Access Framework on Android, the document picker on iOS). Needs
/// no storage or network permission: the caregiver picks each location.
class FilePickerBackupFiles implements BackupFiles {
  const FilePickerBackupFiles();

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    // The complete file is handed to the platform in one call, which writes
    // it to the chosen location.
    final saved = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: BoardBackupFormat.mediaType,
      dialogTitle: 'Save CareBridge backup',
    );
    return saved != null;
  }

  @override
  Future<Uint8List?> open({required int maxBytes}) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const [BoardBackupFormat.fileExtension],
        dialogTitle: 'Choose a CareBridge backup',
      );
      if (file == null) return null;
      final known = file.lengthSync();
      if (known != null && known > maxBytes) {
        // Enough to be recognized as too large; the rest is never read.
        return Uint8List(maxBytes + 1);
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in file.readAsByteStream()) {
        bytes.add(chunk);
        if (bytes.length > maxBytes) break;
      }
      final read = bytes.takeBytes();
      return read.length > maxBytes
          ? Uint8List.sublistView(read, 0, maxBytes + 1)
          : read;
    } finally {
      // Some platforms copy the chosen file into the app's cache first.
      try {
        await FilePicker.clearTemporaryFiles();
      } catch (_) {}
    }
  }
}
