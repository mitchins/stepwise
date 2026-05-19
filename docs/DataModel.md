# Data model

`StepwiseCore` contains pure Swift models for sequential instructions. It has no SwiftUI or extraction dependency.

## Main types

- `StepDocument`: a complete set of sections and steps.
- `StepSection`: an optional section title plus ordered steps.
- `Step`: title, optional detail, kind, duration, timer, icon hint, state, warnings, and metadata.
- `StepKind`: `action`, `wait`, `timer`, `check`, `warning`, `complete`.
- `StepState`: `todo`, `now`, `done`, `skipped`.
- `StepDuration`: exact seconds/minutes/hours or textual timing such as `overnight`.
- `StepTimer`: timer metadata for exact timed steps.

## State

Apps may persist state however they prefer. A document can hold embedded step states, or callers can keep completed/skipped IDs separately:

```swift
let current = document.currentStep(completedIDs: completed, skippedIDs: skipped)
let states = document.stateMap(completedIDs: completed, skippedIDs: skipped)
```

This keeps Stepwise usable with local state, SwiftData, Core Data, cloud state, or app-owned models.
