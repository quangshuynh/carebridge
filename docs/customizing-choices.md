# Customizing choices

Caregivers can change which choices the board shows, what each one looks like, and what it says. Everything happens in settings, on the device, with no account or network connection. The board itself stays one tap per choice and has no editing controls.

## Opening the editor

Hold the settings button on the board for about one second, then choose **Edit choices**. Every editor page has a **Back to board** button.

The **Choices** page lists every choice in board order, including hidden ones. Choosing a row opens that choice's page.

## What a caregiver can do

| Action | Where | Notes |
| --- | --- | --- |
| Add a choice | **Add a choice** on the Choices page | New choices go at the end. A picture must be chosen; CareBridge never picks one. |
| Change the words on the button | **Change words or picture** | Up to 24 characters. |
| Change what is spoken | **Change words or picture** | Up to 150 characters, spoken exactly as written. Independent of the button's words. |
| Change the picture or color | **Change words or picture** | From the built-in pictures and colors below. |
| Reorder | **Move earlier** / **Move later** | The buttons stay in place, so repeated presses never land on a different control. |
| Hide or show | **Hide from board** / **Show on board** | A hidden choice keeps its words, picture, and place. At least one choice must stay shown. |
| Restore the original board | **Restore original six choices** | Asks first. Removes added choices and every change. Export a backup first to keep them. |

Typed text is trimmed, and line breaks or repeated spaces become single spaces. Blank words, blank phrases, and control characters are refused with a message beside the field. Leaving a form with unsaved changes asks first.

A board holds at most 24 choices, shown and hidden together. When it is full, **Add a choice** is unavailable and the page says why.

## How changes are saved

Each change is saved to the device first and shown only once saved. If saving fails, a message says so and nothing changes, on screen or in storage. A change requested while another is still saving is ignored.

The whole board is saved as one value, so a force-close or power loss leaves either the previous board or the new one, never part of each.

## Identity and the confirmation

Every choice has a permanent id. The six built-in choices keep theirs (`food`, `drink`, `drive`, `help`, `rest`, `finished`), and added choices get `custom-1`, `custom-2`, and so on. Editing, hiding, or moving a choice never changes its id.

The confirmation on the board shows only what was actually communicated. If the selected choice's words, phrase, or picture change, or it is hidden, the selection is cleared rather than showing words that were never spoken. Moving a choice does not clear it.

## Existing users and damaged data

With nothing saved, the board shows the original six choices exactly as before, and nothing is written until a caregiver makes a change.

If saved choices cannot be read (for example, damaged storage), the board shows the original six and stays fully usable. The Choices page explains this. The saved data is left alone until the caregiver makes a change, which replaces it.

## Pictures and colors

Pictures come from a fixed set of Material Symbols bundled with the app (Apache 2.0): food, drink, car, raised hand, bed, finish flag, toilet sign, bathtub, moon, house, tree, person walking, toy, ball, game controller, television, tablet, music note, book, graduation cap, two people, heart, phone, clothes hanger, cookie, paw print, sun, snowflake, speaker off, thumbs up, thumbs down, plus, circle with a line, and question mark. Screen readers announce each by what it shows.

Colors are orange, blue, green, red, purple, gray, yellow, pink, teal, and white. Each is light enough that the board's text and icons meet a 7:1 contrast ratio in both standard and high contrast. Color names are shown under each swatch, and the selected one has a check mark, so color is never the only cue.

## Accessibility

- Every editor control is at least 72 points tall, and picture and color options are at least 72 points square.
- Rows are announced as one sentence: the label, the phrase, whether the choice is shown, and its position.
- Picture and color options are announced as a selectable group with their names and selected state.
- Reordering uses ordinary buttons, so it works with TalkBack, VoiceOver, keyboards, and switch access. Buttons stay enabled while a change saves, so focus is not lost.
- Results appear in a bar fixed at the bottom of each page and are announced by screen readers. It never covers or moves the controls.
- Pages honor text size up to twice the default, high contrast, and reduced motion (pages and dialogs appear without transitions).

## Not included yet

- **Personal photos.** Only the built-in pictures are available. Photo support needs file validation, size limits, and backup handling and is deferred to a separate change.
- **Deleting an added choice.** Hide it instead, or restore the original board.
- **Multiple boards or categories.** There is one board.
