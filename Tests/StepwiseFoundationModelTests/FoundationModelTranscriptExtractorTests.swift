import Foundation
import Testing
import StepwiseCore
import StepwiseFoundationModel

#if canImport(FoundationModels)
import FoundationModels
#endif

private func expectFoundationModelUnavailable(
    _ message: String,
    operation: () async throws -> Void
) async {
    do {
        try await operation()
        Issue.record("Expected Foundation Models unavailable error: \(message)")
    } catch let error as StepExtractionError {
        #expect(error == .foundationModelUnavailable(message))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

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
func foundationModelTranscriptExtractorInitStoresTranscriptsAndRejectsBlankInput() async {
    let transcript = FoundationModelTranscript(
        fixtureID: "replay_fixture",
        input: "Review the text.",
        configuration: StepExtractionConfiguration(domain: .generic, title: "Replay Fixture"),
        kind: .replay,
        result: nil,
        error: nil,
        environment: "test"
    )

    let extractor = FoundationModelTranscriptExtractor(
        transcripts: [transcript],
        configuration: transcript.configuration
    )

    #expect(extractor.transcripts == [transcript])
    #expect(extractor.configuration == transcript.configuration)

    await #expect(throws: StepExtractionError.emptyInput) {
        try await extractor.extractSteps(from: "   ")
    }
}

@Test
func foundationModelTranscriptErrorsExposeLocalizedDescriptions() {
    let notFound = FoundationModelTranscriptExtractorError.transcriptNotFound(input: "missing")
    #expect(notFound.errorDescription == "No recorded Foundation Model transcript matched input: missing")

    let missingResult = FoundationModelTranscriptExtractorError.transcriptMissingResult(
        fixtureID: "fixture",
        error: nil,
        environment: "test"
    )
    #expect(
        missingResult.errorDescription
            == "Recorded Foundation Model transcript for fixture did not include a replayable result (recorded error: none, environment: test)."
    )
}

@Test
func foundationModelStepExtractorMapsAllUnavailableReasons() async {
    let unavailableCases: [(FoundationModelDeviceModelUnavailableReason, String)] = [
        (.frameworkUnavailable, "Foundation Models framework is unavailable in this build environment."),
        (.appleIntelligenceNotEnabled, "Foundation Models is unavailable because Apple Intelligence is not enabled."),
        (.deviceNotEligible, "Foundation Models is unavailable because this device is not eligible."),
        (.modelNotReady, "Foundation Models is unavailable because the model is not ready yet."),
        (.unknown, "Foundation Models is unavailable for an unknown reason.")
    ]

    for (reason, expectedMessage) in unavailableCases {
        let deviceModel = FoundationModelDeviceModelStub(
            availability: .unavailable(reason)
        ) { _, _, _ in
            Issue.record("This response handler should not run when availability is unavailable")
            return "{}"
        }

        let extractor = FoundationModelStepExtractor(
            configuration: StepExtractionConfiguration(domain: .generic, title: "Replay Fixture"),
            deviceModel: deviceModel
        )

        await expectFoundationModelUnavailable(expectedMessage) {
            _ = try await extractor.extractSteps(from: "Review the text.")
        }
    }
}

@Test
func foundationModelDeviceModelStubSupportsDirectoryLoadingAndNotFoundErrors() async throws {
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
    let transcript = FoundationModelTranscript(
        fixtureID: "replay_fixture",
        input: "Review the text.",
        configuration: StepExtractionConfiguration(domain: .generic, title: "Replay Fixture"),
        kind: .replay,
        result: StepExtractionResult(
            document: document,
            validationReport: StepValidator().validate(document),
            rawOutput: rawOutput
        ),
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

    let deviceModel = try FoundationModelDeviceModelStub(transcriptDirectoryURL: directoryURL)
    let prompts = StepPromptSet.build(input: transcript.input, configuration: transcript.configuration)
    let response = try await deviceModel.generateResponse(
        for: transcript.input,
        configuration: transcript.configuration,
        prompts: prompts
    )

    #expect(response == rawOutput)

    await #expect(throws: FoundationModelTranscriptExtractorError.transcriptNotFound(input: "Unknown input")) {
        try await deviceModel.generateResponse(
            for: "Unknown input",
            configuration: transcript.configuration,
            prompts: StepPromptSet.build(input: "Unknown input", configuration: transcript.configuration)
        )
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

    await expectFoundationModelUnavailable("Foundation Models is unavailable because this device is not eligible.") {
        _ = try await extractor.extractSteps(from: "Review the text.")
    }
}

@Test
func liveFoundationModelDeviceModelMapsRuntimeAvailabilityWhenUnavailable() async throws {
    #if canImport(FoundationModels)
    guard #available(iOS 26.0, macOS 26.0, *) else {
        return
    }

    let deviceModel = LiveFoundationModelDeviceModel()
    #expect(deviceModel.availability == .available)

    let configuration = StepExtractionConfiguration(domain: .generic, title: "Replay Fixture")
    let prompts = StepPromptSet.build(input: "Review the text.", configuration: configuration)

    switch SystemLanguageModel.default.availability {
    case .available:
        return
    case .unavailable(.appleIntelligenceNotEnabled):
        await expectFoundationModelUnavailable("Foundation Models is unavailable because Apple Intelligence is not enabled.") {
            _ = try await deviceModel.generateResponse(
                for: "Review the text.",
                configuration: configuration,
                prompts: prompts
            )
        }
    case .unavailable(.deviceNotEligible):
        await expectFoundationModelUnavailable("Foundation Models is unavailable because this device is not eligible.") {
            _ = try await deviceModel.generateResponse(
                for: "Review the text.",
                configuration: configuration,
                prompts: prompts
            )
        }
    case .unavailable(.modelNotReady):
        await expectFoundationModelUnavailable("Foundation Models is unavailable because the model is not ready yet.") {
            _ = try await deviceModel.generateResponse(
                for: "Review the text.",
                configuration: configuration,
                prompts: prompts
            )
        }
    @unknown default:
        await expectFoundationModelUnavailable("Foundation Models is unavailable for an unknown reason.") {
            _ = try await deviceModel.generateResponse(
                for: "Review the text.",
                configuration: configuration,
                prompts: prompts
            )
        }
    }
    #endif
}