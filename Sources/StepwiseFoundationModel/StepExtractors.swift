import Foundation

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

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable, message: "Foundation Models extraction is not available on watchOS.")
public struct FoundationModelStepExtractor: StepExtractor {
    public var configuration: StepExtractionConfiguration

    public init(configuration: StepExtractionConfiguration = StepExtractionConfiguration()) {
        self.configuration = configuration
    }

    public func extractSteps(from _: String) async throws -> StepExtractionResult {
        throw StepExtractionError.foundationModelUnavailable(
            "Foundation Model execution is intentionally left as an availability-gated integration point until the SDK API is confirmed in this package's build environment."
        )
    }
}
