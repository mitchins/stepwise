# Validation and normalization

`StepValidator` and `StepNormalizer` help clean and check step content without inventing detail.

## Validation

`StepValidator` returns a `StepValidationReport` with typed issues. It checks:

- empty documents
- empty sections
- empty titles
- overlong titles
- adjacent duplicate steps
- obvious multi-action steps
- ambiguous durations
- model commentary leakage
- missing timers for timer-like steps
- invalid current-state ordering

## Normalization

`StepNormalizer` safely:

- trims whitespace
- collapses duplicate whitespace
- removes prefixes such as `Step 1:`
- sentence-cases all-caps titles
- detects simple durations such as `30 sec`, `5 min`, and `2 hr`
- keeps textual durations such as `overnight`
- avoids exact timers for ambiguous ranges such as `5-7 min`
