import Foundation
public import StepwiseCore

public struct StepExtractionParser: Sendable {
    public var configuration: StepExtractionConfiguration
    public var normalizer: StepNormalizer
    public var validator: StepValidator

    public init(configuration: StepExtractionConfiguration = StepExtractionConfiguration()) {
        self.configuration = configuration
        self.normalizer = StepNormalizer()
        self.validator = StepValidator(maximumTitleLength: configuration.maximumTitleLength)
    }

    public func parse(_ output: String) throws -> StepExtractionResult {
        try parse(output, originalInput: output, repairOutputs: [])
    }

    public func parse(
        _ output: String,
        originalInput: String,
        repairOutputs: [String]
    ) throws -> StepExtractionResult {
        var candidateOutput = output
        var repairs: [StepRepairAttempt] = []
        let allowedRepairOutputs = Array(repairOutputs.prefix(configuration.maximumRepairAttempts))

        while true {
            do {
                let result = try parseOnce(candidateOutput)
                var repairedResult = result
                repairedResult.repairs = repairs
                return repairedResult
            } catch StepExtractionError.validationFailed(let report) {
                guard let nextOutput = allowedRepairOutputs[safe: repairs.count] else {
                    throw StepExtractionError.validationFailed(report)
                }

                let prompt = StepPromptSet.repairPrompt(
                    originalInput: originalInput,
                    previousOutput: candidateOutput,
                    validationReport: report,
                    configuration: configuration
                )
                repairs.append(
                    StepRepairAttempt(
                        prompt: prompt,
                        rawOutput: nextOutput,
                        validationReport: report
                    )
                )
                candidateOutput = nextOutput
            }
        }
    }

    private func parseOnce(_ output: String) throws -> StepExtractionResult {
        let json = try strictJSONObject(from: output)

        do {
            let payload = try JSONDecoder().decode(ExtractionDocumentPayload.self, from: Data(json.utf8))
            let normalized = normalizer.normalize(payload.document())
            let report = validator.validate(normalized)

            guard report.isValid else {
                throw StepExtractionError.validationFailed(report)
            }

            return StepExtractionResult(document: normalized, validationReport: report, rawOutput: output)
        } catch let error as StepExtractionError {
            throw error
        } catch {
            throw StepExtractionError.invalidJSON(error.localizedDescription)
        }
    }

    private func strictJSONObject(from output: String) throws -> String {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw StepExtractionError.emptyInput
        }

        if trimmed.first == "{", trimmed.last == "}" {
            return trimmed
        }

        guard configuration.allowsSafeJSONExtraction,
              let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}"),
              start < end else {
            if trimmed.contains("{") && trimmed.contains("}")
                || trimmed.contains("```") {
                throw StepExtractionError.commentaryWrappedJSON
            }
            throw StepExtractionError.invalidJSON("Output is not a JSON object.")
        }

        return String(trimmed[start...end])
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}

private struct ExtractionDocumentPayload: Decodable {
    var id: String?
    var title: String?
    var summary: String?
    var sections: [ExtractionSectionPayload]
    var estimatedDuration: StepDuration?
    var metadata: [String: String]?

    func document() -> StepDocument {
        StepDocument(
            id: id ?? UUID().uuidString,
            title: title,
            summary: summary,
            sections: sections.map { $0.section() },
            estimatedDuration: estimatedDuration,
            metadata: metadata ?? [:]
        )
    }
}

private struct ExtractionSectionPayload: Decodable {
    var id: String?
    var title: String?
    var steps: [ExtractionStepPayload]

    func section() -> StepSection {
        StepSection(
            id: id ?? UUID().uuidString,
            title: title,
            steps: steps.map { $0.step() }
        )
    }
}

private struct ExtractionStepPayload: Decodable {
    var id: String?
    var title: String
    var detail: String?
    var kind: StepKind?
    var duration: StepDuration?
    var timer: StepTimer?
    var icon: StepIconHint?
    var state: StepState?
    var warnings: [ExtractionWarningPayload]?
    var metadata: [String: String]?

    func step() -> Step {
        Step(
            id: id ?? UUID().uuidString,
            title: title,
            detail: detail,
            kind: kind ?? .action,
            duration: duration,
            timer: timer,
            icon: icon,
            state: state ?? .todo,
            warnings: warnings?.map { $0.warning() } ?? [],
            metadata: metadata ?? [:]
        )
    }
}

private struct ExtractionWarningPayload: Decodable {
    var id: String?
    var message: String
    var severity: StepWarningSeverity?

    func warning() -> StepWarning {
        StepWarning(id: id ?? UUID().uuidString, message: message, severity: severity ?? .note)
    }
}
