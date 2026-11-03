import 'dart:typed_data';

/// The caregiver's own choice of where a backup file goes or comes from,
/// through the platform's file dialogs. Nothing is sent anywhere else.
abstract interface class BackupFiles {
  /// Asks where to save [bytes] as [fileName]. Returns false when the
  /// caregiver cancels; throws when the file cannot be written.
  Future<bool> save({required String fileName, required Uint8List bytes});

  /// Asks for a file to read. Returns null when the caregiver cancels and
  /// never returns more than [maxBytes] + 1 bytes, so a larger file is still
  /// recognized as too large without being read in full. Throws when the
  /// chosen file cannot be read.
  Future<Uint8List?> open({required int maxBytes});
}
