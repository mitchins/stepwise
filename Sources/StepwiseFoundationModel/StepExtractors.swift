import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

public struct MockStepExtractor: StepExtractor {
    public var result: StepExtractionResult

    public init(result: StepExtractionResult) {
        self.result = result
    }

    public func extractSteps(from input: String) async throws -> StepExtractionResult {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StepExtractionError.emptyInput
        }
        return result
    }
}

public struct JSONStepExtractor: StepExtractor {
    public var configuration: StepExtractionConfiguration

    public init(configuration: StepExtractionConfiguration = StepExtractionConfiguration()) {
        self.configuration = configuration
    }

    public func extractSteps(from input: String) async throws -> StepExtractionResult {
        try StepExtractionParser(configuration: configuration).parse(input)
    }
}

@available(watchOS, unavailable, message: "Foundation Models extraction is not available on watchOS.")
public struct FoundationModelStepExtractor: StepExtractor {
    public var configuration: StepExtractionConfiguration

    public init(configuration: StepExtractionConfiguration = StepExtractionConfiguration()) {
        self.configuration = configuration
    }

    public func extractSteps(from input: String) async throws -> StepExtractionResult {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StepExtractionError.emptyInput
        }

        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, *) else {
            throw StepExtractionError.foundationModelUnavailable(
                "Foundation Models live extraction requires iOS 26 or macOS 26 at runtime."
            )
        }

        return try await extractWithFoundationModels(from: input)
        #else
        throw StepExtractionError.foundationModelUnavailable(
            "Foundation Models framework is unavailable in this build environment."
        )
        #endif
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable, message: "Foundation Models extraction is not available on watchOS.")
private extension FoundationModelStepExtractor {
    func extractWithFoundationModels(from input: String) async throws -> StepExtractionResult {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            let prompts = StepPromptSet.build(input: input, configuration: configuration)
            let session = LanguageModelSession(
                model: model,
                tools: [],
                instructions: prompts.system
            )
            let response = try await session.respond(to: prompts.user)
            return try StepExtractionParser(configuration: configuration).parse(
                response.content,
                originalInput: input,
                repairOutputs: []
            )
        case .unavailable(.appleIntelligenceNotEnabled):
            throw StepExtractionError.foundationModelUnavailable(
                "Foundation Models is unavailable because Apple Intelligence is not enabled."
            )
        case .unavailable(.deviceNotEligible):
            throw StepExtractionError.foundationModelUnavailable(
                "Foundation Models is unavailable because this device is not eligible."
            )
        case .unavailable(.modelNotReady):
            throw StepExtractionError.foundationModelUnavailable(
                "Foundation Models is unavailable because the model is not ready yet."
            )
        @unknown default:
            throw StepExtractionError.foundationModelUnavailable(
                "Foundation Models is unavailable for an unknown reason."
            )
        }
    }
}
#endif
