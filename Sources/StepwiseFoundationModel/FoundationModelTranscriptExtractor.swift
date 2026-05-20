import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public enum FoundationModelTranscriptKind: String, Codable, Sendable {
    case live
    case replay
}

public struct FoundationModelTranscript: Codable, Equatable, Sendable {
    public var fixtureID: String
    public var input: String
    public var configuration: StepExtractionConfiguration
    public var kind: FoundationModelTranscriptKind?
    public var result: StepExtractionResult?
    public var error: String?
    public var environment: String

    public init(
        fixtureID: String,
        input: String,
        configuration: StepExtractionConfiguration,
        kind: FoundationModelTranscriptKind? = nil,
        result: StepExtractionResult? = nil,
        error: String? = nil,
        environment: String
    ) {
        self.fixtureID = fixtureID
        self.input = input
        self.configuration = configuration
        self.kind = kind
        self.result = result
        self.error = error
        self.environment = environment
    }
}

public enum FoundationModelTranscriptExtractorError: Error, Equatable, Sendable {
    case transcriptNotFound(input: String)
    case transcriptMissingResult(fixtureID: String, error: String?, environment: String)
}

extension FoundationModelTranscriptExtractorError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .transcriptNotFound(let input):
            return "No recorded Foundation Model transcript matched input: \(input)"
        case .transcriptMissingResult(let fixtureID, let error, let environment):
            let recordedError = error ?? "none"
            return "Recorded Foundation Model transcript for \(fixtureID) did not include a replayable result (recorded error: \(recordedError), environment: \(environment))."
        }
    }
}

public struct FoundationModelTranscriptExtractor: StepExtractor {
    public var configuration: StepExtractionConfiguration
    public var transcripts: [FoundationModelTranscript]

    public init(
        transcripts: [FoundationModelTranscript],
        configuration: StepExtractionConfiguration = StepExtractionConfiguration()
    ) {
        self.configuration = configuration
        self.transcripts = transcripts
    }

    public init(
        transcriptDirectoryURL: URL,
        configuration: StepExtractionConfiguration = StepExtractionConfiguration()
    ) throws {
        self.configuration = configuration
        self.transcripts = try Self.loadTranscripts(from: transcriptDirectoryURL)
    }

    public func extractSteps(from input: String) async throws -> StepExtractionResult {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StepExtractionError.emptyInput
        }

        let deviceModel = FoundationModelDeviceModelStub(transcripts: transcripts)
        return try await FoundationModelStepExtractor(
            configuration: configuration,
            deviceModel: deviceModel
        ).extractSteps(from: input)
    }

    fileprivate static func loadTranscripts(from transcriptDirectoryURL: URL) throws -> [FoundationModelTranscript] {
        let fileManager = FileManager.default
        let transcriptURLs = try fileManager.contentsOfDirectory(
            at: transcriptDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let decoder = JSONDecoder()
        return try transcriptURLs.map { url in
            try decoder.decode(FoundationModelTranscript.self, from: Data(contentsOf: url))
        }
    }
}

public enum FoundationModelDeviceModelAvailability: Equatable, Sendable {
    case available
    case unavailable(FoundationModelDeviceModelUnavailableReason)
}

public enum FoundationModelDeviceModelUnavailableReason: Equatable, Sendable {
    case frameworkUnavailable
    case appleIntelligenceNotEnabled
    case deviceNotEligible
    case modelNotReady
    case unknown

    var foundationModelUnavailableMessage: String {
        switch self {
        case .frameworkUnavailable:
            return "Foundation Models framework is unavailable in this build environment."
        case .appleIntelligenceNotEnabled:
            return "Foundation Models is unavailable because Apple Intelligence is not enabled."
        case .deviceNotEligible:
            return "Foundation Models is unavailable because this device is not eligible."
        case .modelNotReady:
            return "Foundation Models is unavailable because the model is not ready yet."
        case .unknown:
            return "Foundation Models is unavailable for an unknown reason."
        }
    }
}

public protocol FoundationModelDeviceModel: Sendable {
    var availability: FoundationModelDeviceModelAvailability { get }

    func generateResponse(
        for input: String,
        configuration: StepExtractionConfiguration,
        prompts: StepPromptSet
    ) async throws -> String
}

struct FoundationModelUnavailableDeviceModel: FoundationModelDeviceModel {
    var availability: FoundationModelDeviceModelAvailability {
        .unavailable(.frameworkUnavailable)
    }

    func generateResponse(
        for _: String,
        configuration _: StepExtractionConfiguration,
        prompts _: StepPromptSet
    ) async throws -> String {
        throw StepExtractionError.foundationModelUnavailable(
            FoundationModelDeviceModelUnavailableReason.frameworkUnavailable.foundationModelUnavailableMessage
        )
    }
}

public struct FoundationModelDeviceModelStub: FoundationModelDeviceModel {
    public var availability: FoundationModelDeviceModelAvailability
    private let responseHandler: @Sendable (String, StepExtractionConfiguration, StepPromptSet) async throws -> String

    public init(
        availability: FoundationModelDeviceModelAvailability = .available,
        responseHandler: @escaping @Sendable (String, StepExtractionConfiguration, StepPromptSet) async throws -> String
    ) {
        self.availability = availability
        self.responseHandler = responseHandler
    }

    public init(
        transcripts: [FoundationModelTranscript],
        availability: FoundationModelDeviceModelAvailability = .available
    ) {
        self.availability = availability
        self.responseHandler = { input, configuration, _ in
            let matchingTranscripts = transcripts.filter { transcript in
                transcript.input == input && transcript.configuration == configuration
            }

            guard !matchingTranscripts.isEmpty else {
                throw FoundationModelTranscriptExtractorError.transcriptNotFound(input: input)
            }

            if let rawOutput = matchingTranscripts.compactMap({ $0.result?.rawOutput }).first {
                return rawOutput
            }

            let transcript = matchingTranscripts[0]
            throw FoundationModelTranscriptExtractorError.transcriptMissingResult(
                fixtureID: transcript.fixtureID,
                error: transcript.error,
                environment: transcript.environment
            )
        }
    }

    public init(
        transcriptDirectoryURL: URL,
        availability: FoundationModelDeviceModelAvailability = .available
    ) throws {
        self.init(
            transcripts: try FoundationModelTranscriptExtractor.loadTranscripts(from: transcriptDirectoryURL),
            availability: availability
        )
    }

    public func generateResponse(
        for input: String,
        configuration: StepExtractionConfiguration,
        prompts: StepPromptSet
    ) async throws -> String {
        try await responseHandler(input, configuration, prompts)
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, *)
public struct LiveFoundationModelDeviceModel: FoundationModelDeviceModel {
    public init() {
        // No stored state: this adapter resolves the default system model at call time.
    }

    @available(iOS 26.0, macOS 26.0, *)
    public var availability: FoundationModelDeviceModelAvailability {
        .available
    }

    @available(iOS 26.0, macOS 26.0, *)
    public func generateResponse(
        for _: String,
        configuration _: StepExtractionConfiguration,
        prompts: StepPromptSet
    ) async throws -> String {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            let session = LanguageModelSession(
                model: model,
                tools: [],
                instructions: prompts.system
            )
            let response = try await session.respond(to: prompts.user)
            return response.content
        case .unavailable(.appleIntelligenceNotEnabled):
            throw StepExtractionError.foundationModelUnavailable(
                FoundationModelDeviceModelUnavailableReason.appleIntelligenceNotEnabled.foundationModelUnavailableMessage
            )
        case .unavailable(.deviceNotEligible):
            throw StepExtractionError.foundationModelUnavailable(
                FoundationModelDeviceModelUnavailableReason.deviceNotEligible.foundationModelUnavailableMessage
            )
        case .unavailable(.modelNotReady):
            throw StepExtractionError.foundationModelUnavailable(
                FoundationModelDeviceModelUnavailableReason.modelNotReady.foundationModelUnavailableMessage
            )
        @unknown default:
            throw StepExtractionError.foundationModelUnavailable(
                FoundationModelDeviceModelUnavailableReason.unknown.foundationModelUnavailableMessage
            )
        }
    }
}
#endif