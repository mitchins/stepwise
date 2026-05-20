# SwiftUI views

`StepwiseUI` provides Apple-native SwiftUI views backed by `StepwiseCore`.

## Views

- `StepCardView`: focused card for the active step.
- `StepRowView`: single list row.
- `StepListView`: sectioned grouped list.
- `StepFlowView` / `StepPagerView`: adaptive flow layout, best treated as a convenience/demo composition.
- `StepProgressDots`: compact progress indicator.
- `StepSectionHeaderView`: section label.
- `StepCompletionView`: completion state.
- `StepRailView`: iPad/macOS-style step rail.
- `WatchStepRailView`: compact watchOS-style rail.

## Theme

Use `StepwiseTheme` for tint, done, warning, skipped, spacing, corner radius, and icon style.

## Integrating into an existing app

For serious app integrations, compose the presenter shell yourself from `StepCardView`, `StepProgressDots`, and the smaller list/row primitives. Treat `StepFlowView` / `StepPagerView` as a convenience/demo composition rather than the required shell.

Keep timers, ingredients, batching, voice controls, persistence, diagnostics, and other app-specific state outside Stepwise. In presenter mode, avoid duplicate current-step summaries, engine lights, full step lists, and debug panels. Surface compact current-step metadata only when it adds signal.

## Future API idea

A future `StepPresentationView(document:currentStepID:mode:onPrevious:onNext:onPrimaryAction:)` could provide a focused modal/sheet presenter for downstream apps, but Stepwise intentionally does not ship that shell yet.

The default theme uses system colors, SF Symbols by name, Dynamic Type text styles, accessible labels, and reduced-motion-aware progress animation.
