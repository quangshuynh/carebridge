# Device validation

This checklist is for testing CareBridge on physical phones and tablets. It is a **software usability** checklist. It is not a clinical assessment protocol and does not evaluate the communicator.

!!! warning "Put the person first"
    Test CareBridge alongside the person's existing ways of communicating. Never punish, withhold something from, or pressure a communicator into using CareBridge for the sake of a test.

The current build has not yet completed this checklist on physical devices.

## Before each session

Record the device model, operating system version, CareBridge commit, date, and orientation. Do not record private information in the repository.

## Device checks

### Launch and appearance

- [ ] The home screen icon shows the CareBridge mark and the name "CareBridge".
- [ ] The app opens directly to the six-choice board without an account or network connection, including in airplane mode.
- [ ] The launch screen shows only the mark on the board's light background, with no white or black flash, including when the system is in dark mode.

### Layout and touch

- [ ] All six choices are visible at once, without scrolling, in phone and tablet portrait and landscape.
- [ ] Choices stay clear of notches, rounded corners, and system bars.
- [ ] Choices are large, do not overlap, and respond across their full visible area.
- [ ] One tap immediately shows the configured phrase and a border and check on the selected choice. Confirmation does not cover another choice.
- [ ] Selection requires no swipe, long press, hover, or other gesture-only action.

### Repeats and switching

- [ ] A rapid double tap on one choice produces only one communication. A deliberate repeat after about 0.6 seconds works.
- [ ] Switching immediately to a different choice updates the visual confirmation and replaces speech rather than queuing it.

### Speech

- [ ] Each phrase is understandable through the device speaker at the volume of the intended environment. Also check muted and low-volume behavior.
- [ ] On iPhone and iPad, speech stays audible with the ring/silent switch or silent mode on, and other audio briefly lowers rather than stopping.
- [ ] The first choice after launch is spoken without a noticeably longer delay than later choices.
- [ ] The visual confirmation remains usable when speech is unavailable or interrupted.

### Haptics

- [ ] Each accepted choice gives one light haptic tap on devices that support it, with system touch feedback on.
- [ ] A rapid repeat gives no extra tap.
- [ ] The board works the same with vibration or touch feedback turned off.

### Leaving and returning

- [ ] Selecting a choice and immediately leaving CareBridge (home, app switcher, or lock) stops speech.
- [ ] Returning shows the same selection and does not replay or resume the old phrase.
- [ ] A phone call or the notification shade alone does not change the selection.
- [ ] Note whether edge swipes (the Android back gesture or the iOS home indicator) or the back button cause accidental exits. CareBridge does not block them. Android app pinning or iOS Guided Access can keep the app on screen if caregivers choose to use them.

### Accessibility settings

- [ ] At the largest practical accessibility text size, choices remain reachable and important text stays understandable without layout errors.
- [ ] With TalkBack on Android or VoiceOver on Apple devices, each choice is announced as an enabled button with its label, phrase hint, and selected state.
- [ ] Note whether the screen reader's announcement of the confirmation overlaps the spoken phrase.
- [ ] Reduced-motion settings do not add unnecessary motion.

### Custom choices

- [ ] Edit choices is reachable only from settings; nothing on the board starts editing.
- [ ] Adding a choice with the on-screen keyboard works in portrait and landscape, and the keyboard does not hide the field being typed in.
- [ ] A changed spoken phrase is what the device speaks; the button's words stay as set.
- [ ] Pressing Move earlier or Move later repeatedly never lands on a different button.
- [ ] Hidden choices disappear from the board and come back in the same place.
- [ ] Custom choices survive force-closing, a device restart, rotating, and leaving and returning to the app.
- [ ] Restore original six choices asks first and then shows exactly the original board.
- [ ] With TalkBack and VoiceOver, rows, picture and color options, reorder buttons, and result messages are announced, and reordering works.
- [ ] With a Bluetooth keyboard or switch access, focus stays on Move earlier or Move later after each move.
- [ ] At the largest text size on a small phone, every editor page is usable.

### High contrast and settings

- [ ] Tapping or briefly pressing the settings button does nothing. Holding it for about one second opens settings.
- [ ] With TalkBack or VoiceOver, double-tap and hold on "Settings" opens settings.
- [ ] Turning on High contrast changes the board at once. Text, icons, and borders are clearly darker, and the selected choice is still obvious in bright light and glare.
- [ ] High contrast is still on after force-closing and reopening CareBridge, and after a device restart.
- [ ] On iPhone and iPad, turning on Settings, Accessibility, Display & Text Size, Increase Contrast switches CareBridge to high contrast.

### Backup and restore

- [ ] Export board backup opens the system save dialog, saves `carebridge-backup-YYYY-MM-DD.json`, and shows "Backup saved". Cancelling shows "Export cancelled".
- [ ] Exporting works in airplane mode to a local folder.
- [ ] Importing that file on a second device shows the confirmation and, after Replace settings, turns on high contrast that survives a restart.
- [ ] Importing a non-JSON file, an edited file, and a file with `"schemaVersion": 3` each shows a clear message and changes nothing.
- [ ] A backup with custom choices restores the same words, phrases, pictures, order, and hidden choices on a second device.
- [ ] A version 1 backup (made before custom choices) imports its settings and leaves custom choices unchanged.
- [ ] With TalkBack or VoiceOver, the backup buttons, confirmation, and result messages are announced.
- [ ] The merged release Android manifest requests no new permissions.
- [ ] On Android 14 or later, note which system contrast setting (if any) switches CareBridge to high contrast.
- [ ] Opening settings while a phrase is speaking stops it. Returning shows the same selection and does not replay the phrase.
- [ ] With a Bluetooth keyboard or switch access, a focus ring is clearly visible on the focused choice.

## Caregiver observations

Observe the interaction. Do not coach toward a preferred result or guess at a cause.

- Was a target selected intentionally?
- Was the intended target clear to the caregiver?
- Was accidental or repeated activation observed?
- Was the visual confirmation noticeable and understandable?
- Was the spoken phrase understandable?
- Did the communicator appear to recognize any picture?
- Was any choice consistently ignored?
- Did the caregiver still have to guess what the selection meant?
- Did device position, reach, glare, volume, or orientation affect the interaction?

## Interpreting results

Record only what happened and what the software displayed or spoke.

!!! danger "What a test result can and cannot mean"
    A result such as **"the software interaction was not understood"** is a finding about CareBridge.

    It does **not** mean **"the person is incapable of using AAC."** CareBridge testing cannot establish that, and that conclusion must never be drawn from it. CareBridge does not replace evaluation by a qualified AAC professional.

## Result notes

For each observation, note:

- the selected target,
- the expected phrase,
- the displayed phrase,
- the spoken result,
- any steps needed to reproduce a device problem.

Avoid medical, psychological, behavioral, or cognitive conclusions.
