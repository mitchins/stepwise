import Foundation
import Testing
import StepwiseFoundationModel

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

private func withTemporaryEnvironmentVariable<R>(
    _ name: String,
    value: String,
    body: () -> R
) -> R {
    let previousValue = name.withCString { getenv($0) }.map { String(cString: $0) }
    _ = name.withCString { setenv($0, value, 1) }

    defer {
        _ = name.withCString { namePointer in
            if let previousValue {
                previousValue.withCString { valuePointer in
                    setenv(namePointer, valuePointer, 1)
                }
            } else {
                unsetenv(namePointer)
            }
        }
    }

    return body()
}

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
func foundationModelLiveHarnessCanRecordAndReplayStubbedTranscript() async throws {
    let fixture = FoundationModelSanityFixtures.all[0]
    let transcriptsDirectoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("stepwise-foundation-model-transcripts-\(UUID().uuidString)", isDirectory: true)

    try FileManager.default.createDirectory(at: transcriptsDirectoryURL, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: transcriptsDirectoryURL)
    }

    let extractor = FoundationModelStepExtractor(
        configuration: fixture.configuration,
        deviceModel: FoundationModelDeviceModelStub { input, configuration, _ in
            #expect(input == fixture.input)
            #expect(configuration == fixture.configuration)
            return fixture.referenceOutput
        }
    )

    let result = try await extractor.extractSteps(from: fixture.input)
    #expect(fixture.rubricFailures(for: result).isEmpty)

    withTemporaryEnvironmentVariable(FoundationModelLiveTestHarness.transcriptEnvironmentVariable, value: "1") {
        FoundationModelLiveTestHarness.recordTranscript(
            fixture: fixture,
            kind: .live,
            result: result,
            error: nil,
            transcriptsDirectoryURL: transcriptsDirectoryURL
        )
    }

    let transcriptURL = transcriptsDirectoryURL.appendingPathComponent("\(fixture.id).live.json")
    let transcriptData = try Data(contentsOf: transcriptURL)
    let transcript = try JSONDecoder().decode(FoundationModelTranscript.self, from: transcriptData)

    #expect(transcript.fixtureID == fixture.id)
    #expect(transcript.kind == .live)
    #expect(transcript.result == result)

    let replayExtractor = try FoundationModelTranscriptExtractor(
        transcriptDirectoryURL: transcriptsDirectoryURL,
        configuration: fixture.configuration
    )
    let replayResult = try await replayExtractor.extractSteps(from: fixture.input)

    #expect(replayResult.rawOutput == result.rawOutput)
    #expect(fixture.rubricFailures(for: replayResult).isEmpty)
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
            FoundationModelLiveTestHarness.recordTranscript(
                fixture: fixture,
                kind: .live,
                result: result,
                error: nil
            )

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
            FoundationModelLiveTestHarness.recordTranscript(
                fixture: fixture,
                kind: .live,
                result: nil,
                error: error
            )
            if let replayResult = try? StepExtractionParser(configuration: fixture.configuration).parse(
                fixture.referenceOutput,
                originalInput: fixture.input,
                repairOutputs: []
            ) {
                FoundationModelLiveTestHarness.recordTranscript(
                    fixture: fixture,
                    kind: .replay,
                    result: replayResult,
                    error: error
                )
            }
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