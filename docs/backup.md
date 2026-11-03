# Backup and restore

Caregivers can save CareBridge's settings and the board's choices to a file and restore them on another device. There is no account and no cloud service: the caregiver chooses where the file goes and how it is moved.

## Using it

Open **Settings** (hold the settings button for about one second), then scroll to **Backup**.

- **Export board backup** opens the device's save dialog. Choose a place such as Files, Downloads, or a USB drive. The suggested name is `carebridge-backup-YYYY-MM-DD.json`. Exporting never changes anything.
- **Import board backup** opens the device's file picker. CareBridge checks the whole file first. If it is valid, a confirmation shows each setting now and after the import, and the choices the board will show. **Replace settings** applies it; **Keep current settings** changes nothing.

A message under the buttons reports every result: saved, cancelled, could not be saved, imported, not a backup, from a newer version, damaged, too large, or could not be applied. Every failure leaves the current settings as they were.

## What a backup contains

| Included | Not included |
| --- | --- |
| The **High contrast** setting. | Communication history or events. They are never stored. |
| Every choice on the board, in order: its id, words, spoken phrase, picture, color, and whether it is shown. | Personal photos. CareBridge does not support them yet; pictures are referenced by built-in name only. |
| | Names, accounts, device or user identifiers, timestamps, or file paths. |
| | Medical, diagnostic, or profile information. CareBridge does not collect it. |
| | The device's speech, text size, or system accessibility settings. |

Everything CareBridge saves is backed up: the high-contrast setting and the choices. See [Customizing choices](customizing-choices.md).

## File format

A backup is UTF-8 JSON. CareBridge writes version 2:

```json
{
  "format": "carebridge.board-backup",
  "schemaVersion": 2,
  "settings": {
    "highContrast": false
  },
  "board": {
    "choices": [
      {
        "id": "food",
        "label": "Food",
        "phrase": "I would like something to eat.",
        "icon": "food",
        "color": "orange",
        "visible": true
      }
    ]
  }
}
```

A real backup lists every choice on the board.

| Field | Rule |
| --- | --- |
| `format` | Required. Exactly `"carebridge.board-backup"`. |
| `schemaVersion` | Required. A whole number. `1` and `2` are supported; a higher number is refused as a backup from a newer CareBridge. |
| `settings` | Required object. |
| `settings.highContrast` | Optional `true` or `false`. If absent, the standard value (`false`) is used, never the device's current value. |
| `board` | Required in version 2, not allowed in version 1. An object with only `choices`. |
| `board.choices` | A list of 1 to 24 choices in board order. Order is the position in the list, so it cannot be missing or repeated. At least one must be visible. |
| `id` | Lowercase letters, digits, and hyphens, starting with a letter or digit, at most 40 characters, unique on the board. |
| `label` | 1 to 24 characters, trimmed and single-spaced, no control characters. |
| `phrase` | 1 to 150 characters, with the same text rules. |
| `icon`, `color` | A built-in picture or color name. Paths, URLs, and color codes are refused. |
| `visible` | `true` or `false`. |

Every choice field is required.

### Version 1 backups

Backups made before choices could be changed (version 1) still import. They contain only settings, so importing one replaces the settings and leaves the current choices exactly as they are. The confirmation says so.

Export always writes the same bytes for the same settings: fixed field order, two-space indentation, and a final newline.

## Import checks

Import reads the file as data only. Nothing in it is run, opened, or followed. The file is refused, and nothing changes, if it:

- is larger than 64 KiB (a full board of the longest choices is well under this),
- is not UTF-8 text or not valid JSON (a leading byte order mark is allowed),
- lacks the `format` value,
- has a `schemaVersion` that is missing, not a whole number, below 1, or newer than 1,
- has any field not listed above, including paths, URLs, or embedded content,
- repeats a field name, or
- has a value of the wrong type, including `null`,
- has a choice that breaks any rule above, including a repeated id, an unknown picture or color, or no visible choice.

## Atomic replacement

Import replaces settings and choices; it never merges. The new choices are saved first, then the new settings, and only once both are saved does anything on screen change. If the choices cannot be saved, nothing changes. If the settings cannot be saved after the choices were, the previous choices are saved back and nothing on screen changes. Import is refused while saved choices are still loading at startup.

Export hands the complete file to the platform in one call. Whether an interrupted write can leave a partial file depends on the destination app; CareBridge never writes the file in pieces.

## Platform notes

Files are saved and opened through the system's document dialogs (the Storage Access Framework on Android, the document picker on iOS and iPadOS) using [`file_picker`](https://pub.dev/packages/file_picker). No storage or network permission is requested. If a cloud folder is chosen in those dialogs, that transfer is the caregiver's choice and is handled by the device, not CareBridge.
