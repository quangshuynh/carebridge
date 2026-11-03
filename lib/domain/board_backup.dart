import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'display_preferences.dart';

/// Everything a CareBridge backup carries: the caregiver settings this app
/// saves on the device. The board's choices are built in and are not part of
/// a backup, and neither is anything about who uses the app or what they
/// communicated.
@immutable
class BoardBackup {
  const BoardBackup({required this.displayPreferences});

  final DisplayPreferences displayPreferences;

  @override
  bool operator ==(Object other) =>
      other is BoardBackup && other.displayPreferences == displayPreferences;

  @override
  int get hashCode => displayPreferences.hashCode;
}

/// Why a file was not accepted as a backup.
enum BoardBackupProblem {
  /// Larger than [BoardBackupFormat.maxBytes].
  tooLarge,

  /// Empty, not UTF-8 text, not JSON, or not a CareBridge backup at all.
  notBackup,

  /// A CareBridge backup from a newer, unsupported schema version.
  newerVersion,

  /// A CareBridge backup with a missing, unknown, repeated, or invalid field.
  invalidContent,
}

class BoardBackupException implements Exception {
  const BoardBackupException(this.problem, this.detail);
  final BoardBackupProblem problem;

  /// For developers and tests; never shown to the person using the board.
  final String detail;

  @override
  String toString() => 'BoardBackupException(${problem.name}): $detail';
}

/// Version 1 of the backup file. A backup is small UTF-8 JSON data with a
/// fixed set of fields; nothing in it is ever run, opened, or followed.
///
/// ```json
/// {
///   "format": "carebridge.board-backup",
///   "schemaVersion": 1,
///   "settings": {
///     "highContrast": false
///   }
/// }
/// ```
abstract final class BoardBackupFormat {
  static const formatId = 'carebridge.board-backup';
  static const schemaVersion = 1;

  /// Far above any valid backup, small enough to read and check at once.
  static const maxBytes = 16 * 1024;
  static const fileExtension = 'json';
  static const mediaType = 'application/json';

  static const _rootFields = {'format', 'schemaVersion', 'settings'};
  static const _settingsFields = {'highContrast'};

  /// A sensible file name that names no person or device.
  static String fileNameFor(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'carebridge-backup-${date.year}-${two(date.month)}-'
        '${two(date.day)}.$fileExtension';
  }

  /// The same backup always produces the same text: fixed field order,
  /// two-space indentation, and a final newline.
  static String encode(BoardBackup backup) {
    final document = <String, Object>{
      'format': formatId,
      'schemaVersion': schemaVersion,
      'settings': <String, Object>{
        'highContrast': backup.displayPreferences.highContrast,
      },
    };
    return '${const JsonEncoder.withIndent('  ').convert(document)}\n';
  }

  static Uint8List encodeBytes(BoardBackup backup) =>
      utf8.encode(encode(backup));

  /// Reads a whole file and returns the backup only if every part of it is
  /// valid. Throws [BoardBackupException] otherwise; nothing is applied here.
  static BoardBackup decode(List<int> bytes) {
    if (bytes.length > maxBytes) {
      throw BoardBackupException(
        BoardBackupProblem.tooLarge,
        '${bytes.length} bytes exceeds the $maxBytes byte limit',
      );
    }
    final String text;
    try {
      text = const Utf8Decoder().convert(bytes);
    } on FormatException {
      throw const BoardBackupException(
        BoardBackupProblem.notBackup,
        'not UTF-8 text',
      );
    }
    // Some editors start UTF-8 files with a byte order mark.
    final json = text.startsWith('﻿') ? text.substring(1) : text;
    final Object? root;
    try {
      root = jsonDecode(json);
    } on FormatException {
      throw const BoardBackupException(
        BoardBackupProblem.notBackup,
        'not valid JSON',
      );
    }
    if (root is! Map<String, Object?> || root['format'] != formatId) {
      throw const BoardBackupException(
        BoardBackupProblem.notBackup,
        'missing "format": "$formatId"',
      );
    }
    // Checked before the other fields: a newer backup may use fields this
    // version does not know, and should say so rather than look damaged.
    final version = root['schemaVersion'];
    if (version is! int || version < 1) {
      throw _invalid('"schemaVersion" must be a whole number from 1');
    }
    if (version > schemaVersion) {
      throw BoardBackupException(
        BoardBackupProblem.newerVersion,
        'schema version $version is newer than $schemaVersion',
      );
    }
    final repeated = _firstRepeatedField(json);
    if (repeated != null) throw _invalid('"$repeated" appears more than once');
    _onlyKnownFields(root, _rootFields, 'the backup');

    final settings = root['settings'];
    if (settings is! Map<String, Object?>) {
      throw _invalid('"settings" must be an object');
    }
    _onlyKnownFields(settings, _settingsFields, '"settings"');
    final highContrast = settings['highContrast'];
    if (settings.containsKey('highContrast') && highContrast is! bool) {
      throw _invalid('"highContrast" must be true or false');
    }
    // An absent setting means the standard default, never "keep the current
    // value", so the result of an import never depends on the device.
    return BoardBackup(
      displayPreferences: DisplayPreferences(
        highContrast:
            highContrast as bool? ?? DisplayPreferences.standard.highContrast,
      ),
    );
  }

  static BoardBackupException _invalid(String detail) =>
      BoardBackupException(BoardBackupProblem.invalidContent, detail);

  static void _onlyKnownFields(
    Map<String, Object?> object,
    Set<String> known,
    String where,
  ) {
    for (final field in object.keys) {
      if (!known.contains(field)) {
        throw _invalid('unknown field "$field" in $where');
      }
    }
  }

  /// The first object field that appears twice, which [jsonDecode] would
  /// otherwise resolve silently by keeping the last value. [json] must
  /// already be valid JSON.
  static String? _firstRepeatedField(String json) {
    // One entry per open object (its field names) or array (null).
    final open = <Set<String>?>[];
    var expectingField = false;
    var i = 0;
    while (i < json.length) {
      final char = json[i];
      if (char == '"') {
        var end = i + 1;
        while (json[end] != '"') {
          end += json[end] == r'\' ? 2 : 1;
        }
        if (expectingField) {
          final field = jsonDecode(json.substring(i, end + 1)) as String;
          if (!open.last!.add(field)) return field;
          expectingField = false;
        }
        i = end + 1;
        continue;
      }
      switch (char) {
        case '{':
          open.add(<String>{});
          expectingField = true;
        case '[':
          open.add(null);
        case '}' || ']':
          open.removeLast();
        case ',':
          expectingField = open.last != null;
      }
      i++;
    }
    return null;
  }
}
