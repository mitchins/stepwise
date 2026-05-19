import Foundation

public enum StepKind: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case action
    case wait
    case timer
    case check
    case warning
    case complete
}

public enum StepState: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case todo
    case now
    case done
    case skipped
}

public enum StepDuration: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    case seconds(Int)
    case minutes(Int)
    case hours(Int)
    case textual(String)

    public var exactSeconds: Int? {
        switch self {
        case .seconds(let value):
            value
        case .minutes(let value):
            value * 60
        case .hours(let value):
            value * 3_600
        case .textual:
            nil
        }
    }

    public var isExact: Bool {
        exactSeconds != nil
    }

    public var description: String {
        switch self {
        case .seconds(let value):
            "\(value) sec"
        case .minutes(let value):
            "\(value) min"
        case .hours(let value):
            "\(value) hr"
        case .textual(let value):
            value
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case value
    }

    private enum Kind: String, Codable {
        case seconds
        case minutes
        case hours
        case textual
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .seconds:
            self = .seconds(try container.decode(Int.self, forKey: .value))
        case .minutes:
            self = .minutes(try container.decode(Int.self, forKey: .value))
        case .hours:
            self = .hours(try container.decode(Int.self, forKey: .value))
        case .textual:
            self = .textual(try container.decode(String.self, forKey: .value))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .seconds(let value):
            try container.encode(Kind.seconds, forKey: .kind)
            try container.encode(value, forKey: .value)
        case .minutes(let value):
            try container.encode(Kind.minutes, forKey: .kind)
            try container.encode(value, forKey: .value)
        case .hours(let value):
            try container.encode(Kind.hours, forKey: .kind)
            try container.encode(value, forKey: .value)
        case .textual(let value):
            try container.encode(Kind.textual, forKey: .kind)
            try container.encode(value, forKey: .value)
        }
    }
}

public struct StepTimer: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var title: String?
    public var duration: StepDuration
    public var automaticallyStarts: Bool

    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        duration: StepDuration,
        automaticallyStarts: Bool = false
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.automaticallyStarts = automaticallyStarts
    }

    public var exactSeconds: Int? {
        duration.exactSeconds
    }
}

public struct StepIconHint: Codable, Equatable, Hashable, Sendable {
    public var symbolName: String
    public var accessibilityLabel: String?

    public init(symbolName: String, accessibilityLabel: String? = nil) {
        self.symbolName = symbolName
        self.accessibilityLabel = accessibilityLabel
    }
}

public enum StepWarningSeverity: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case note
    case caution
    case critical
}

public struct StepWarning: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var message: String
    public var severity: StepWarningSeverity

    public init(
        id: String = UUID().uuidString,
        message: String,
        severity: StepWarningSeverity = .note
    ) {
        self.id = id
        self.message = message
        self.severity = severity
    }
}

public struct Step: Codable, Equatable, Hashable, Identifiable, Sendable {
    public struct Timing: Codable, Equatable, Hashable, Sendable {
        public var duration: StepDuration?
        public var timer: StepTimer?

        public init(duration: StepDuration? = nil, timer: StepTimer? = nil) {
            self.duration = duration
            self.timer = timer
        }
    }

    public struct Annotations: Codable, Equatable, Hashable, Sendable {
        public var icon: StepIconHint?
        public var warnings: [StepWarning]
        public var metadata: [String: String]

        public init(
            icon: StepIconHint? = nil,
            warnings: [StepWarning] = [],
            metadata: [String: String] = [:]
        ) {
            self.icon = icon
            self.warnings = warnings
            self.metadata = metadata
        }
    }

    public var id: String
    public var title: String
    public var detail: String?
    public var kind: StepKind
    public var duration: StepDuration?
    public var timer: StepTimer?
    public var icon: StepIconHint?
    public var state: StepState
    public var warnings: [StepWarning]
    public var metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        title: String,
        detail: String? = nil,
        kind: StepKind = .action,
        state: StepState = .todo,
        timing: Timing = Timing(),
        annotations: Annotations = Annotations()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.kind = kind
        self.duration = timing.duration
        self.timer = timing.timer
        self.icon = annotations.icon
        self.state = state
        self.warnings = annotations.warnings
        self.metadata = annotations.metadata
    }
}

public struct StepSection: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var title: String?
    public var steps: [Step]

    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        steps: [Step]
    ) {
        self.id = id
        self.title = title
        self.steps = steps
    }
}

public struct StepDocument: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var title: String?
    public var summary: String?
    public var sections: [StepSection]
    public var estimatedDuration: StepDuration?
    public var metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        summary: String? = nil,
        sections: [StepSection],
        estimatedDuration: StepDuration? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.sections = sections
        self.estimatedDuration = estimatedDuration
        self.metadata = metadata
    }
}

public struct StepProgress: Codable, Equatable, Hashable, Sendable {
    public var totalCount: Int
    public var doneCount: Int
    public var skippedCount: Int
    public var currentIndex: Int?

    public init(totalCount: Int, doneCount: Int, skippedCount: Int, currentIndex: Int?) {
        self.totalCount = totalCount
        self.doneCount = doneCount
        self.skippedCount = skippedCount
        self.currentIndex = currentIndex
    }

    public var completedCount: Int {
        doneCount + skippedCount
    }

    public var isComplete: Bool {
        totalCount > 0 && completedCount >= totalCount
    }
}

public extension StepDocument {
    var steps: [Step] {
        sections.flatMap(\.steps)
    }

    var currentStep: Step? {
        steps.first { $0.state == .now } ?? steps.first { $0.state != .done && $0.state != .skipped }
    }

    var currentStepIndex: Int? {
        let allSteps = steps
        if let nowIndex = allSteps.firstIndex(where: { $0.state == .now }) {
            return nowIndex
        }
        return allSteps.firstIndex { $0.state != .done && $0.state != .skipped }
    }

    func step(withID id: Step.ID) -> Step? {
        steps.first { $0.id == id }
    }

    func currentStep(completedIDs: Set<Step.ID>, skippedIDs: Set<Step.ID>) -> Step? {
        steps.first { step in
            !completedIDs.contains(step.id) && !skippedIDs.contains(step.id)
        }
    }

    func stateMap(
        completedIDs: Set<Step.ID> = [],
        skippedIDs: Set<Step.ID> = [],
        preferredActiveID: Step.ID? = nil
    ) -> [Step.ID: StepState] {
        let allSteps = steps
        let activeID = preferredActiveID.flatMap { candidate -> Step.ID? in
            guard allSteps.contains(where: { $0.id == candidate }),
                  !completedIDs.contains(candidate),
                  !skippedIDs.contains(candidate) else {
                return nil
            }
            return candidate
        } ?? allSteps.first { step in
            !completedIDs.contains(step.id) && !skippedIDs.contains(step.id)
        }?.id

        return Dictionary(allSteps.map { step in
            let state: StepState
            if completedIDs.contains(step.id) {
                state = .done
            } else if skippedIDs.contains(step.id) {
                state = .skipped
            } else if step.id == activeID {
                state = .now
            } else {
                state = .todo
            }
            return (step.id, state)
        }, uniquingKeysWith: { first, _ in first })
    }

    func applyingStates(
        completedIDs: Set<Step.ID> = [],
        skippedIDs: Set<Step.ID> = [],
        preferredActiveID: Step.ID? = nil
    ) -> StepDocument {
        let states = stateMap(
            completedIDs: completedIDs,
            skippedIDs: skippedIDs,
            preferredActiveID: preferredActiveID
        )

        var copy = self
        copy.sections = sections.map { section in
            var sectionCopy = section
            sectionCopy.steps = section.steps.map { step in
                var stepCopy = step
                stepCopy.state = states[step.id] ?? .todo
                return stepCopy
            }
            return sectionCopy
        }
        return copy
    }

    func preferringCurrentStep(_ preferredActiveID: Step.ID?) -> StepDocument {
        guard let preferredActiveID,
              let preferredActiveIndex = steps.enumerated().first(where: { _, step in
                  step.id == preferredActiveID && step.state != .done && step.state != .skipped
              })?.offset else {
            return self
        }

        var copy = self
        var flatIndex = 0
        copy.sections = sections.map { section in
            var sectionCopy = section
            sectionCopy.steps = section.steps.map { step in
                let currentFlatIndex = flatIndex
                flatIndex += 1
                var stepCopy = step
                guard stepCopy.state != .done && stepCopy.state != .skipped else {
                    return stepCopy
                }
                stepCopy.state = currentFlatIndex == preferredActiveIndex ? .now : .todo
                return stepCopy
            }
            return sectionCopy
        }
        return copy
    }

    func progress(completedIDs: Set<Step.ID> = [], skippedIDs: Set<Step.ID> = []) -> StepProgress {
        let allSteps = steps
        let current = allSteps.firstIndex { step in
            !completedIDs.contains(step.id) && !skippedIDs.contains(step.id)
        }
        return StepProgress(
            totalCount: allSteps.count,
            doneCount: allSteps.filter { completedIDs.contains($0.id) }.count,
            skippedCount: allSteps.filter { skippedIDs.contains($0.id) }.count,
            currentIndex: current
        )
    }
}
