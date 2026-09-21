# CareBridge agent guidance

- Communication works offline, without an account, with core data stored locally.
- Use very large targets, first-class visuals, minimal navigation, and immediate feedback. Never assume literacy.
- Accessibility is architecture: preserve semantics, contrast, text scaling, orientation support, and deliberate tablet layouts.
- A selection means only its configured phrase. Never infer intent, diagnose, or make medical claims.
- Keep profiles, categories, choices, visuals, phrases, ordering, enabled state, and events as domain data, not widget state.
- Preserve future caregiver customization without easy-to-trigger editing controls on the board.
- Do not add authentication, cloud sync, analytics, advertising, AI/LLM features, or medical APIs without an explicit product decision.
- Prefer small vertical slices and straightforward Flutter/Dart over speculative layers.
- Use owned or safely licensed visuals. Never invent missing user information.
- Test domain behavior, interaction, duplicate activation, semantics, and phone/tablet layouts.
- Do not weaken checks to make CI pass. Document device-only verification still outstanding.
