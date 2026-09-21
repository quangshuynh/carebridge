# Real-device validation checklist

This is a software usability checklist, not a clinical assessment protocol. Test
CareBridge alongside the person's existing communication methods. Never punish,
deny something to, or pressure a communicator into using CareBridge for a test.

Record the device model, operating-system version, CareBridge commit, date, and
orientation for each session. Do not record private information in the repository.

## Device verification

- [ ] The app launches directly to the six-choice board without an account or
      network connection.
- [ ] All six choices remain reachable in phone and tablet portrait and landscape.
- [ ] Choices are large, do not overlap, and respond across their full visible area.
- [ ] One tap immediately shows the configured phrase and a border/checkmark on
      the selected choice; confirmation does not cover another choice.
- [ ] A rapid double-tap on one choice produces only one communication, while a
      deliberate repeat after about 0.6 seconds works.
- [ ] Switching immediately to a different choice updates the visual confirmation
      and replaces speech rather than building a speech queue.
- [ ] Each configured phrase is understandable through the device speaker at the
      intended environment's volume. Also check muted and low-volume behavior.
- [ ] The visual action remains usable when speech is unavailable or interrupted.
- [ ] At the largest practical accessibility text setting, choices remain reachable
      and important text remains understandable without layout errors.
- [ ] With TalkBack on Android or VoiceOver on Apple devices, each choice is
      announced as an enabled button with its label, phrase hint, and selected state.
- [ ] Selection requires no swipe, long-press, hover, or other gesture-only action.
- [ ] Reduced-motion settings do not add unnecessary motion.

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
