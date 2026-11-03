# Backup and restore

Caregivers can save CareBridge's settings to a file and restore them on another device. There is no account and no cloud service: the caregiver chooses where the file goes and how it is moved.

## Using it

Open **Settings** (hold the settings button for about one second), then scroll to **Backup**.

- **Export board backup** opens the device's save dialog. Choose a place such as Files, Downloads, or a USB drive. The suggested name is `carebridge-backup-YYYY-MM-DD.json`. Exporting never changes anything.
- **Import board backup** opens the device's file picker. CareBridge checks the whole file first. If it is valid, a confirmation shows each setting now and after the import. **Replace settings** applies it; **Keep current settings** changes nothing.

A message under the buttons reports every result: saved, cancelled, could not be saved, imported, not a backup, from a newer version, damaged, too large, or could not be applied. Every failure leaves the current settings as they were.

## What a backup contains

| Included | Not included |
| --- | --- |
| The **High contrast** setting. | The board's choices, pictures, and phrases. They are built in, not yet editable, and always present. |
| | Communication history or events. They are never stored. |
| | Names, accounts, device or user identifiers, timestamps, or file paths. |
| | Medical, diagnostic, or profile information. CareBridge does not collect it. |
| | The device's speech, text size, or system accessibility settings. |

High contrast is the only setting CareBridge saves, so it is the only one backed up. When caregiver-editable choices exist, they will be added in a new schema version.

## File format

A backup is UTF-8 JSON. Version 1 is exactly:

```json
{
  "format": "carebridge.board-backup",
  "schemaVersion": 1,
  "settings": {
    "highContrast": false
  }
}
```

| Field | Rule |
| --- | --- |
| `format` | Required. Exactly `"carebridge.board-backup"`. |
| `schemaVersion` | Required. A whole number. `1` is supported; a higher number is refused as a backup from a newer CareBridge. |
| `settings` | Required object. |
| `settings.highContrast` | Optional `true` or `false`. If absent, the standard value (`false`) is used, never the device's current value. |

Export always writes the same bytes for the same settings: fixed field order, two-space indentation, and a final newline.

## Import checks

Import reads the file as data only. Nothing in it is run, opened, or followed. The file is refused, and nothing changes, if it:

- is larger than 16 KiB,
- is not UTF-8 text or not valid JSON (a leading byte order mark is allowed),
- lacks the `format` value,
- has a `schemaVersion` that is missing, not a whole number, below 1, or newer than 1,
- has any field not listed above, including paths, URLs, or embedded content,
- repeats a field name, or
- has a value of the wrong type, including `null`.

## Atomic replacement

Import replaces settings; it never merges. The new settings are saved to device storage first and shown only once saved. If saving fails, the previous settings stay in effect and in storage. The built-in choices, speech, and the board are unaffected either way.

Export hands the complete file to the platform in one call. Whether an interrupted write can leave a partial file depends on the destination app; CareBridge never writes the file in pieces.

## Platform notes

Files are saved and opened through the system's document dialogs (the Storage Access Framework on Android, the document picker on iOS and iPadOS) using [`file_picker`](https://pub.dev/packages/file_picker). No storage or network permission is requested. If a cloud folder is chosen in those dialogs, that transfer is the caregiver's choice and is handled by the device, not CareBridge.
