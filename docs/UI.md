# SwiftUI views

`StepwiseUI` provides Apple-native SwiftUI views backed by `StepwiseCore`.

## Views

- `StepCardView`: focused card for the active step.
- `StepRowView`: single list row.
- `StepListView`: sectioned grouped list.
- `StepFlowView` / `StepPagerView`: adaptive flow layout.
- `StepProgressDots`: compact progress indicator.
- `StepSectionHeaderView`: section label.
- `StepCompletionView`: completion state.
- `StepRailView`: iPad/macOS-style step rail.
- `WatchStepRailView`: compact watchOS-style rail.

## Theme

Use `StepwiseTheme` for tint, done, warning, skipped, spacing, corner radius, and icon style.

The default theme uses system colors, SF Symbols by name, Dynamic Type text styles, accessible labels, and reduced-motion-aware progress animation.
