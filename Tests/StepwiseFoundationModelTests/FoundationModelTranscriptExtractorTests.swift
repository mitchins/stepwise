import Foundation
import Testing
import StepwiseCore
import StepwiseFoundationModel

@Test
func foundationModelTranscriptExtractorReplaysRecordedResultFromDisk() async throws {
    let document = StepDocument(
        sections: [
            StepSection(
                steps: [
                    Step(id: "one", title: "Review the text")
                ]
            )
        ]
    )
    let rawOutputData = try JSONEncoder().encode(document)
    let rawOutput = String(decoding: rawOutputData, as: UTF8.self)
    let expected = StepExtractionResult(
        document: document,
        validationReport: StepValidator().validate(document),
        rawOutput: rawOutput
    )
    let transcript = FoundationModelTranscript(
        fixtureID: "replay_fixture",
        input: "Review the text.",
        configuration: StepExtractionConfiguration(domain: .generic, title: "Replay Fixture"),
        kind: .replay,
        result: expected,
        error: nil,
        environment: "test"
    )

    let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let data = try JSONEncoder().encode(transcript)
    try data.write(to: directoryURL.appendingPathComponent("replay_fixture.json"), options: .atomic)

    let extractor = try FoundationModelTranscriptExtractor(
        transcriptDirectoryURL: directoryURL,
        configuration: transcript.configuration
    )

    let result = try await extractor.extractSteps(from: transcript.input)

    #expect(result == expected)
}

@Test
func foundationModelTranscriptExtractorReportsMissingResultExplicitly() async throws {
    let transcript = FoundationModelTranscript(
        fixtureID: "failure_fixture",
        input: "Review the text.",
        configuration: StepExtractionConfiguration(domain: .generic, title: "Replay Fixture"),
        kind: .live,
        result: nil,
        error: "deviceNotEligible",
        environment: "test"
    )

    let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let data = try JSONEncoder().encode(transcript)
    try data.write(to: directoryURL.appendingPathComponent("failure_fixture.json"), options: .atomic)

    let extractor = try FoundationModelTranscriptExtractor(
        transcriptDirectoryURL: directoryURL,
        configuration: transcript.configuration
    )

    do {
        _ = try await extractor.extractSteps(from: transcript.input)
        Issue.record("Expected transcript replay failure")
    } catch let error as FoundationModelTranscriptExtractorError {
        switch error {
        case .transcriptMissingResult(let fixtureID, let recordedError, let environment):
            #expect(fixtureID == transcript.fixtureID)
            #expect(recordedError == transcript.error)
            #expect(environment == transcript.environment)
        default:
            Issue.record("Unexpected transcript replay error: \(error)")
        }
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test
func foundationModelStepExtractorCanReplayThroughInjectedDeviceModel() async throws {
    let document = StepDocument(
        sections: [
            StepSection(
                steps: [
                    Step(id: "one", title: "Review the text")
                ]
            )
        ]
    )
    let rawOutputData = try JSONEncoder().encode(document)
    let rawOutput = String(decoding: rawOutputData, as: UTF8.self)
    let expected = StepExtractionResult(
        document: document,
        validationReport: StepValidator().validate(document),
        rawOutput: rawOutput
    )
    let transcript = FoundationModelTranscript(
        fixtureID: "replay_fixture",
        input: "Review the text.",
        configuration: StepExtractionConfiguration(domain: .generic, title: "Replay Fixture"),
        kind: .replay,
        result: expected,
        error: nil,
        environment: "test"
    )

    let extractor = FoundationModelStepExtractor(
        configuration: transcript.configuration,
        deviceModel: FoundationModelDeviceModelStub(transcripts: [transcript])
    )

    let result = try await extractor.extractSteps(from: transcript.input)

    #expect(result == expected)
}

@Test
func foundationModelStepExtractorHonorsInjectedDeviceModelAvailability() async {
    let deviceModel = FoundationModelDeviceModelStub(
        availability: .unavailable(.deviceNotEligible)
    ) { _, _, _ in
        Issue.record("This response handler should not run when availability is unavailable")
        return "{}"
    }

    let extractor = FoundationModelStepExtractor(
        configuration: StepExtractionConfiguration(domain: .generic, title: "Replay Fixture"),
        deviceModel: deviceModel
    )

    await #expect(throws: StepExtractionError.foundationModelUnavailable("Foundation Models is unavailable because this device is not eligible.")) {
        try await extractor.extractSteps(from: "Review the text.")
    }
}