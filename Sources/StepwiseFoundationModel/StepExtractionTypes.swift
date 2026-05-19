import Foundation
public import StepwiseCore

public protocol StepExtractor: Sendable {
    func extractSteps(from input: String) async throws -> StepExtractionResult
}

public enum StepDomain: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case generic
    case recipe
    case filmDevelopment
    case onboarding
    case checklist
}

public struct StepExtractionConfiguration: Codable, Equatable, Sendable {
    public var domain: StepDomain
    public var title: String?
    public var maximumRepairAttempts: Int
    public var allowsSafeJSONExtraction: Bool
    public var maximumTitleLength: Int

    public init(
        domain: StepDomain = .generic,
        title: String? = nil,
        maximumRepairAttempts: Int = 1,
        allowsSafeJSONExtraction: Bool = false,
        maximumTitleLength: Int = 80
    ) {
        self.domain = domain
        self.title = title
        self.maximumRepairAttempts = max(0, maximumRepairAttempts)
        self.allowsSafeJSONExtraction = allowsSafeJSONExtraction
        self.maximumTitleLength = maximumTitleLength
    }
}

public struct StepExtractionResult: Codable, Equatable, Sendable {
    public var document: StepDocument
    public var validationReport: StepValidationReport
    public var repairs: [StepRepairAttempt]
    public var rawOutput: String?

    public init(
        document: StepDocument,
        validationReport: StepValidationReport = StepValidationReport(),
        repairs: [StepRepairAttempt] = [],
        rawOutput: String? = nil
    ) {
        self.document = document
        self.validationReport = validationReport
        self.repairs = repairs
        self.rawOutput = rawOutput
    }
}

public struct StepPromptSet: Codable, Equatable, Sendable {
    public var system: String
    public var user: String
    public var schema: StepSchema

    public init(system: String, user: String, schema: StepSchema = .stepDocument) {
        self.system = system
        self.user = user
        self.schema = schema
    }

    public static func build(input: String, configuration: StepExtractionConfiguration = StepExtractionConfiguration()) -> StepPromptSet {
        StepPromptSet(
            system: systemPrompt(for: configuration.domain),
            user: userPrompt(input: input, configuration: configuration),
            schema: .stepDocument
        )
    }

    public static func repairPrompt(
        originalInput: String,
        previousOutput: String,
        validationReport: StepValidationReport,
        configuration: StepExtractionConfiguration = StepExtractionConfiguration()
    ) -> String {
        let issueSummary = validationReport.issues.map { "- \($0.code.rawValue): \($0.message) at \($0.path)" }.joined(separator: "\n")
        return """
        Repair the JSON output so it satisfies the Stepwise schema and validation rules.
        Return strict JSON only. No prose. No Markdown.
        Do not invent missing ingredients, tools, chemicals, measurements, temperatures, or times.

        Domain: \(configuration.domain.rawValue)

        Validation issues:
        \(issueSummary)

        Original input:
        \(originalInput)

        Previous output:
        \(previousOutput)
        """
    }

    private static func systemPrompt(for domain: StepDomain) -> String {
        """
        You convert plain text into Stepwise step documents.
        Return strict JSON only. No prose. No Markdown. No code fences.
        Use short imperative titles. Use optional detail for clarification.
        Preserve measurements, quantities, temperatures, timings, safety notes, and meaningful warnings.
        Split obvious multi-action instructions.
        Do not invent missing ingredients, tools, chemicals, temperatures, or times.
        If unsure, put ambiguity in detail or warnings instead of invented precision.
        Domain guidance: \(domainGuidance(for: domain))
        """
    }

    private static func userPrompt(input: String, configuration: StepExtractionConfiguration) -> String {
        """
        Build one StepDocument from this input.
        Preferred title: \(configuration.title ?? "none")
        Domain: \(configuration.domain.rawValue)

        Output contract:
        \(StepSchema.stepDocument.description)

        Input:
        \(input)
        """
    }

    private static func domainGuidance(for domain: StepDomain) -> String {
        switch domain {
        case .generic:
            "Keep steps generic and do not add app-specific concepts."
        case .recipe:
            "For recipes, preserve ingredient quantities, measurements, temperatures, resting, baking, simmering, and cooling times."
        case .filmDevelopment:
            "For film development, preserve timings, agitation cadence, dilution, temperature, chemical names, and safety notes."
        case .onboarding:
            "For onboarding, keep steps brief, direct, and reversible where possible."
        case .checklist:
            "For checklists, use checkable action titles and avoid unnecessary detail."
        }
    }
}

public struct StepSchema: Codable, Equatable, Sendable {
    public var name: String
    public var description: String

    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }

    public static let stepDocument = StepSchema(
        name: "StepDocument",
        description: """
        StepDocument JSON object:
        {
          "id": "optional stable string",
          "title": "optional string",
          "summary": "optional string",
          "sections": [
            {
              "id": "optional stable string",
              "title": "optional string",
              "steps": [
                {
                  "id": "optional stable string",
                  "title": "required short imperative string",
                  "detail": "optional string",
                  "kind": "action|wait|timer|check|warning|complete",
                  "duration": {"kind":"seconds|minutes|hours|textual","value":30},
                  "timer": {"id":"optional string","title":"optional string","duration":{"kind":"minutes","value":5},"automaticallyStarts":false},
                  "icon": {"symbolName":"optional SF Symbol name","accessibilityLabel":"optional string"},
                  "state": "todo|now|done|skipped",
                  "warnings": [{"message":"string","severity":"note|caution|critical"}],
                  "metadata": {"key":"value"}
                }
              ]
            }
          ],
          "estimatedDuration": {"kind":"minutes","value":30},
          "metadata": {"key":"value"}
        }
        """
    )
}

public struct StepRepairAttempt: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var prompt: String
    public var rawOutput: String?
    public var validationReport: StepValidationReport?

    public init(
        id: String? = nil,
        prompt: String,
        rawOutput: String? = nil,
        validationReport: StepValidationReport? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.prompt = prompt
        self.rawOutput = rawOutput
        self.validationReport = validationReport
    }
}

public enum StepExtractionError: Error, Equatable, Sendable {
    case emptyInput
    case commentaryWrappedJSON
    case invalidJSON(String)
    case validationFailed(StepValidationReport)
    case foundationModelUnavailable(String)
}
