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

The availability-gated `FoundationModelStepExtractor` is a placeholder until real SDK APIs are confirmed. It does not import or call unavailable Foundation Model APIs.
