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

@available(watchOS, unavailable, message: "Foundation Models extraction is not available on watchOS.")
public struct FoundationModelStepExtractor: StepExtractor {
    public var configuration: StepExtractionConfiguration
    private let deviceModel: any FoundationModelDeviceModel

    public init(configuration: StepExtractionConfiguration = StepExtractionConfiguration()) {
        self.configuration = configuration

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            self.deviceModel = LiveFoundationModelDeviceModel()
        } else {
            self.deviceModel = FoundationModelUnavailableDeviceModel()
        }
        #else
        self.deviceModel = FoundationModelUnavailableDeviceModel()
        #endif
    }

    public init<D: FoundationModelDeviceModel>(
        configuration: StepExtractionConfiguration = StepExtractionConfiguration(),
        deviceModel: D
    ) {
        self.configuration = configuration
        self.deviceModel = deviceModel
    }

    public func extractSteps(from input: String) async throws -> StepExtractionResult {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StepExtractionError.emptyInput
        }

        switch deviceModel.availability {
        case .available:
            let prompts = StepPromptSet.build(input: input, configuration: configuration)
            let response = try await deviceModel.generateResponse(
                for: input,
                configuration: configuration,
                prompts: prompts
            )
            return try StepExtractionParser(configuration: configuration).parse(
                response,
                originalInput: input,
                repairOutputs: []
            )
        case .unavailable(let reason):
            throw StepExtractionError.foundationModelUnavailable(
                reason.foundationModelUnavailableMessage
            )
        }
    }
}
