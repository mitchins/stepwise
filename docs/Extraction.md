# Optional extraction scaffolding

`StepwiseFoundationModel` is optional. It depends on `StepwiseCore`, but Core and UI do not depend on it.

## Types

- `StepExtractor`
- `StepExtractionConfiguration`
- `StepDomain`
- `StepExtractionResult`
- `StepPromptSet`
- `StepSchema`
- `StepRepairAttempt`
- `StepExtractionError`
- `StepExtractionParser`
- `MockStepExtractor`
- `JSONStepExtractor`
- `FoundationModelStepExtractor`

## Behavior

The extraction layer provides strict JSON prompt text, a StepDocument output contract, deterministic JSON parsing, validation after parse, repair prompt hooks, and testable mocks.

`FoundationModelStepExtractor` uses the live Foundation Models runtime only when the framework, API availability, and device/runtime state all allow it. Otherwise it throws `foundationModelUnavailable(...)` with an explicit reason instead of pretending the runtime exists.

## Live sanity checks

Deterministic parser/schema tests always run as part of the normal `swift test` flow.

Live Foundation Models sanity checks are opt-in and require:

```bash
STEPWISE_RUN_FOUNDATION_MODEL_TESTS=1 swift test
```

The live suite is compile-gated with `canImport(FoundationModels)`, runtime-gated for iOS 26 / macOS 26, and skipped when Apple Intelligence is disabled, the device is ineligible, or the model assets are not ready. The live harness uses stable fixture prompts with rubric-based assertions and prints per-fixture latency plus a summary line for manual performance tracking.
