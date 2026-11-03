// Backup format (issue #8): versioned, deterministic, and parsed as data
// only, with every invalid file rejected as a whole.
import 'dart:convert';

import 'package:carebridge/domain/board_backup.dart';
import 'package:carebridge/domain/display_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

const _highContrast = BoardBackup(
  displayPreferences: DisplayPreferences(highContrast: true),
);
const _standard = BoardBackup(displayPreferences: DisplayPreferences.standard);

BoardBackup _decodeText(String text) =>
    BoardBackupFormat.decode(utf8.encode(text));

Matcher _rejectedAs(BoardBackupProblem problem) => throwsA(
  isA<BoardBackupException>().having((e) => e.problem, 'problem', problem),
);

String _withSettings(String settings, {Object version = 1}) =>
    '{"format": "carebridge.board-backup", "schemaVersion": $version, '
    '"settings": $settings}';

void main() {
  group('encode', () {
    test('writes the documented version 1 document exactly', () {
      expect(
        BoardBackupFormat.encode(_highContrast),
        '{\n'
        '  "format": "carebridge.board-backup",\n'
        '  "schemaVersion": 1,\n'
        '  "settings": {\n'
        '    "highContrast": true\n'
        '  }\n'
        '}\n',
      );
    });

    test('is deterministic', () {
      expect(
        BoardBackupFormat.encodeBytes(_highContrast),
        BoardBackupFormat.encodeBytes(_highContrast),
      );
      expect(
        BoardBackupFormat.encode(_standard),
        isNot(BoardBackupFormat.encode(_highContrast)),
      );
    });

    test('holds only the format, version, and supported settings', () {
      final document = jsonDecode(
        BoardBackupFormat.encode(_standard),
      ) as Map<String, Object?>;
      expect(document.keys, ['format', 'schemaVersion', 'settings']);
      expect((document['settings']! as Map).keys, ['highContrast']);
      // No paths, identifiers, timestamps, or history.
      final text = BoardBackupFormat.encode(_standard);
      expect(text, isNot(contains('/')));
      expect(text, isNot(contains(r'\')));
    });

    test('the file name is sensible and names no person or device', () {
      expect(
        BoardBackupFormat.fileNameFor(DateTime(2026, 3, 7, 13, 45)),
        'carebridge-backup-2026-03-07.json',
      );
    });
  });

  group('round trip', () {
    for (final backup in [_standard, _highContrast]) {
      test(
        'restores ${backup.displayPreferences.highContrast ? 'high '
                  'contrast' : 'the default configuration'} identically',
        () {
          final bytes = BoardBackupFormat.encodeBytes(backup);
          final restored = BoardBackupFormat.decode(bytes);
          expect(restored, backup);
          expect(BoardBackupFormat.encodeBytes(restored), bytes);
        },
      );
    }
  });

  group('optional fields', () {
    test('a missing setting takes the standard default', () {
      expect(_decodeText(_withSettings('{}')), _standard);
    });

    test('field order and whitespace do not matter', () {
      expect(
        _decodeText(
          '{"settings":{"highContrast":true},"schemaVersion":1,'
          '"format":"carebridge.board-backup"}',
        ),
        _highContrast,
      );
    });

    test('a leading UTF-8 byte order mark is accepted', () {
      expect(
        _decodeText('\uFEFF${BoardBackupFormat.encode(_highContrast)}'),
        _highContrast,
      );
    });

    test('settings itself is required', () {
      expect(
        () => _decodeText(
          '{"format": "carebridge.board-backup", "schemaVersion": 1}',
        ),
        _rejectedAs(BoardBackupProblem.invalidContent),
      );
    });
  });

  group('rejects', () {
    final notBackups = {
      'an empty file': '',
      'whitespace': '   \n',
      'malformed JSON': '{"format": "carebridge.board-backup", ',
      'a trailing comma': _withSettings('{"highContrast": true,}'),
      'a JSON array': '[1, 2, 3]',
      'a JSON string': '"carebridge.board-backup"',
      'null': 'null',
      'another app\'s JSON': '{"name": "something else"}',
      'a missing format': '{"schemaVersion": 1, "settings": {}}',
      'a different format': _withSettings('{}')
          .replaceFirst('board-backup', 'board-backup-x'),
      'a look-alike format':
          '{"format": "carebridge.board\u2010backup", "schemaVersion": 1, '
          '"settings": {}}',
      'a script': '<script>alert(1)</script>',
    };
    notBackups.forEach((name, text) {
      test(name, () {
        expect(
          () => _decodeText(text),
          _rejectedAs(BoardBackupProblem.notBackup),
        );
      });
    });

    test('bytes that are not UTF-8 text', () {
      expect(
        () => BoardBackupFormat.decode([0x7B, 0xFF, 0xFE, 0x7D]),
        _rejectedAs(BoardBackupProblem.notBackup),
      );
    });

    test('a future schema version, even with fields this version does not '
        'know', () {
      expect(
        () => _decodeText(_withSettings('{}', version: 2)),
        _rejectedAs(BoardBackupProblem.newerVersion),
      );
      expect(
        () => _decodeText(
          '{"format": "carebridge.board-backup", "schemaVersion": 99, '
          '"board": {"choices": []}}',
        ),
        _rejectedAs(BoardBackupProblem.newerVersion),
      );
    });

    final invalid = {
      'a missing version':
          '{"format": "carebridge.board-backup", "settings": {}}',
      'version 0': _withSettings('{}', version: 0),
      'a negative version': _withSettings('{}', version: -1),
      'a fractional version': _withSettings('{}', version: 1.5),
      'a version written as text': _withSettings('{}', version: '"1"'),
      'settings that are not an object': _withSettings('[]'),
      'settings that are null': _withSettings('null'),
      'high contrast as text': _withSettings('{"highContrast": "true"}'),
      'high contrast as a number': _withSettings('{"highContrast": 1}'),
      'high contrast as null': _withSettings('{"highContrast": null}'),
      'an unknown setting': _withSettings('{"fontScale": 2}'),
      'an unknown top-level field': BoardBackupFormat.encode(_standard)
          .replaceFirst('{', '{"note": "hello",'),
      'a repeated setting': _withSettings(
        '{"highContrast": false, "highContrast": true}',
      ),
      'a repeated top-level field': _withSettings('{}')
          .replaceFirst('{', '{"schemaVersion": 1, '),
      'a repeated field written with escapes': _withSettings(
        r'{"highContrast": false, "high\u0043ontrast": true}',
      ),
      'a path': _withSettings('{"image": "/sdcard/DCIM/photo.jpg"}'),
      'a Windows path': _withSettings(r'{"image": "C:\\Users\\me\\a.png"}'),
      'a URL': _withSettings('{"sound": "https://example.com/a.mp3"}'),
      'a file URL': BoardBackupFormat.encode(_standard)
          .replaceFirst('{', '{"import": "file:///etc/passwd",'),
      // Hostile-looking text is only ever data, and is rejected as unknown.
      'embedded code': _withSettings(
        '{"highContrast": true, "onLoad": "Function(\'x\')()"}',
      ),
      'a usage history': BoardBackupFormat.encode(_standard)
          .replaceFirst('{', '{"events": [{"choiceId": "help"}],'),
      'Unicode in an unknown field': _withSettings(
        '{"名前": "écoute 👋", "highContrast": true}',
      ),
    };
    invalid.forEach((name, text) {
      test(name, () {
        expect(
          () => _decodeText(text),
          _rejectedAs(BoardBackupProblem.invalidContent),
        );
      });
    });

    test('a file over the size limit, before reading it as text', () {
      final padded = BoardBackupFormat.encode(_standard)
          .padRight(BoardBackupFormat.maxBytes + 1);
      expect(
        () => _decodeText(padded),
        _rejectedAs(BoardBackupProblem.tooLarge),
      );
      // Exactly at the limit is still read normally.
      final atLimit = BoardBackupFormat.encode(_highContrast)
          .padRight(BoardBackupFormat.maxBytes);
      expect(_decodeText(atLimit), _highContrast);
    });

    test('deeply nested data within the size limit', () {
      final depth = BoardBackupFormat.maxBytes ~/ 2 - 100;
      final nested = '${'[' * depth}${']' * depth}';
      expect(
        () => _decodeText(_withSettings('{"x": $nested}')),
        _rejectedAs(BoardBackupProblem.invalidContent),
      );
    });
  });

  test('quoted structure and Unicode inside strings are read as text, not '
      'as fields', () {
    // The braces, commas, and escaped quotes inside "x" must not be mistaken
    // for a repeated "highContrast"; the file is rejected for its unknown
    // field instead.
    expect(
      () => _decodeText(
        _withSettings(
          r'{"highContrast": true, "x": "{\"highContrast\": 1, é 😀}"}',
        ),
      ),
      throwsA(
        isA<BoardBackupException>().having(
          (e) => e.detail,
          'detail',
          'unknown field "x" in "settings"',
        ),
      ),
    );
  });
}
