# Privacy

CareBridge is designed so that communication stays on the device and works without a network.

## Summary

| Question | Current answer |
| --- | --- |
| Is an account required? | No. |
| Does CareBridge's own code make network requests? | No. |
| Is there analytics, tracking, or advertising? | No. |
| Is anything synced to a cloud service? | No. |
| Is anything saved between sessions? | Only the high-contrast display setting, on the device. |
| Can speech involve the network? | That depends on the device's speech engine. See [Text-to-speech](#text-to-speech). |

## Local-first design

Core communication must remain available offline and on the device. The board opens and works without an account or connection. Confirming this in airplane mode on real devices is part of the [device validation checklist](device-validation.md).

CareBridge has no authentication, cloud synchronization, analytics, advertising, or AI features. Adding any of these would require an explicit product decision.

## Communication events

Each accepted selection creates an event holding the choice, its phrase, and the time. Events are kept in memory only for the running session. They are not written to storage, not displayed, and not sent anywhere. Closing the app discards them.

Durable local storage of communication is deliberately deferred until its data lifecycle and caregiver controls are designed.

## Display settings

The high-contrast setting is the only thing CareBridge saves. It is stored on the device with [`shared_preferences`](https://pub.dev/packages/shared_preferences) (SharedPreferences on Android, UserDefaults on iOS) and is never sent anywhere by CareBridge. Like other app data, it may be included in the device's own backups if the person has turned those on.

## Network access

CareBridge's own code makes no network requests.

The release Android build requests no internet permission. Debug and profile builds include it only because Flutter's development tools need it to connect to the running app.

## Text-to-speech

CareBridge's speech package, [`flutter_tts`](https://pub.dev/packages/flutter_tts), passes each phrase to the operating system's text-to-speech engine. CareBridge does not select network voices.

Whether the system speech engine uses network services is controlled by the device and its settings, not by CareBridge. It should not be assumed to be offline on every device.
