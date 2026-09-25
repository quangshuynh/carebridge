# Real-device validation checklist

This is a software usability checklist, not a clinical assessment protocol. Test
CareBridge alongside the person's existing communication methods. Never punish,
deny something to, or pressure a communicator into using CareBridge for a test.

Record the device model, operating-system version, CareBridge commit, date, and
orientation for each session. Do not record private information in the repository.

## Device verification

- [ ] The home-screen icon shows the CareBridge mark and the name "CareBridge".
- [ ] The app launches directly to the six-choice board without an account or
      network connection, including in airplane mode. The launch screen shows
      only the mark on the board's light background, with no white or black
      flash, also when the system is in dark mode.
- [ ] All six choices are visible at once, without scrolling, in phone and
      tablet portrait and landscape, and stay clear of notches, rounded
      corners, and system bars.
- [ ] Choices are large, do not overlap, and respond across their full visible area.
- [ ] One tap immediately shows the configured phrase and a border/checkmark on
      the selected choice; confirmation does not cover another choice.
- [ ] A rapid double-tap on one choice produces only one communication, while a
      deliberate repeat after about 0.6 seconds works.
- [ ] Switching immediately to a different choice updates the visual confirmation
      and replaces speech rather than building a speech queue.
- [ ] Each configured phrase is understandable through the device speaker at the
      intended environment's volume. Also check muted and low-volume behavior.
- [ ] On iPhone/iPad, speech remains audible with the ring/silent switch (or
      silent mode) on, and other audio briefly lowers rather than stopping.
- [ ] The first choice after launch is spoken without a noticeably longer delay
      than later choices.
- [ ] Each accepted choice gives one light haptic tap on devices that support it
      (with system touch feedback on); a rapid repeat gives no extra tap. The
      board works the same with vibration or touch feedback turned off.
- [ ] The visual action remains usable when speech is unavailable or interrupted.
- [ ] Selecting a choice and immediately leaving CareBridge (home, app switcher,
      lock) stops speech. Returning shows the same selection and does not
      replay or resume the old phrase. A phone call or notification shade
      alone does not change the selection.
- [ ] At the largest practical accessibility text setting, choices remain reachable
      and important text remains understandable without layout errors.
- [ ] With TalkBack on Android or VoiceOver on Apple devices, each choice is
      announced as an enabled button with its label, phrase hint, and selected state.
      Note whether the screen reader's announcement of the confirmation overlaps
      or talks over the spoken phrase.
- [ ] Selection requires no swipe, long-press, hover, or other gesture-only action.
- [ ] Reduced-motion settings do not add unnecessary motion.
- [ ] Note whether edge swipes (Android back gesture, iOS home indicator) or
      the back button cause accidental exits during use. CareBridge does not
      block them; Android app pinning or iOS Guided Access can hold the app
      on screen during a session if caregivers choose to use them.

## Caregiver-observed usability

Observe the interaction; do not coach toward a preferred result or infer a cause.

- Was a target intentionally selected?
- Was the intended target clear to the caregiver?
- Was accidental or repeated activation observed?
- Was the visual confirmation understandable and noticeable?
- Was the spoken phrase understandable?
- Did the communicator appear to recognize any visual?
- Was any choice consistently ignored?
- Did the caregiver still have to guess what the selection meant?
- Did device position, reach, glare, volume, or orientation affect the interaction?

Record only what happened and what the software displayed or spoke. A result such
as **"the software interaction was not understood"** does not mean **"the person is
incapable of using AAC."** CareBridge cannot establish the latter and does not
replace evaluation by a qualified AAC professional.

## Result notes

For each observation, note the selected target, expected phrase, displayed phrase,
spoken result, and any reproducible device steps. Avoid medical, psychological,
behavioral, or cognitive conclusions.
