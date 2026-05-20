import Testing
import StepwiseFoundationModel

@Test
func foundationModelExtractorRejectsBlankInputBeforeLiveExecution() async {
    let extractor = FoundationModelStepExtractor()

    await #expect(throws: StepExtractionError.emptyInput) {
        try await extractor.extractSteps(from: "   ")
    }
}

@Test
func foundationModelReferenceFixturesMatchRubrics() throws {
    for fixture in FoundationModelSanityFixtures.all {
        let result = try StepExtractionParser(configuration: fixture.configuration).parse(
            fixture.referenceOutput,
            originalInput: fixture.input,
            repairOutputs: []
        )

        let failures = fixture.rubricFailures(for: result)
        if !failures.isEmpty {
            Issue.record("Fixture \(fixture.id) failed rubric checks: \(failures.joined(separator: " | "))")
        }
    }
}

@Test
func liveFoundationModelFixtureSuite() async throws {
    guard FoundationModelLiveTestHarness.shouldRun(testName: #function) else {
        return
    }

    let clock = ContinuousClock()
    var measurements: [FoundationModelFixtureMeasurement] = []

    for fixture in FoundationModelSanityFixtures.all {
        let extractor = FoundationModelStepExtractor(configuration: fixture.configuration)
        let start = clock.now
        do {
            let result = try await extractor.extractSteps(from: fixture.input)
            let duration = start.duration(to: clock.now)
            let failures = fixture.rubricFailures(for: result)

            measurements.append(
                FoundationModelFixtureMeasurement(
                    fixtureID: fixture.id,
                    duration: duration,
                    stepCount: result.document.steps.count,
                    rawOutputLength: result.rawOutput?.count ?? 0
                )
            )

            if !failures.isEmpty {
                Issue.record("Live fixture \(fixture.id) failed rubric checks: \(failures.joined(separator: " | "))")
            }
        } catch {
            let duration = start.duration(to: clock.now)
            measurements.append(
                FoundationModelFixtureMeasurement(
                    fixtureID: fixture.id,
                    duration: duration,
                    stepCount: 0,
                    rawOutputLength: 0
                )
            )
            Issue.record("Live fixture \(fixture.id) extraction failed: \(error.localizedDescription)")
        }
    }

    FoundationModelLiveTestHarness.log(measurements: measurements)
}