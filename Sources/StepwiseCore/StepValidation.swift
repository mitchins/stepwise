import Foundation

public enum StepValidationSeverity: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case warning
    case error
}

public enum StepValidationCode: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case emptyDocument
    case emptySection
    case emptyTitle
    case overlongTitle
    case adjacentDuplicateStep
    case multiActionStep
    case ambiguousDuration
    case modelCommentaryLeakage
    case missingTimer
    case invalidStateOrdering
}

public struct StepValidationIssue: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var severity: StepValidationSeverity
    public var code: StepValidationCode
    public var message: String
    public var path: String

    public init(
        id: String? = nil,
        severity: StepValidationSeverity,
        code: StepValidationCode,
        message: String,
        path: String
    ) {
        self.id = id ?? "\(severity.rawValue):\(code.rawValue):\(path):\(message)"
        self.severity = severity
        self.code = code
        self.message = message
        self.path = path
    }
}

public struct StepValidationReport: Codable, Equatable, Sendable {
    public var issues: [StepValidationIssue]

    public init(issues: [StepValidationIssue] = []) {
        self.issues = issues
    }

    public var isValid: Bool {
        !issues.contains { $0.severity == .error }
    }

    public func contains(_ code: StepValidationCode) -> Bool {
        issues.contains { $0.code == code }
    }
}

public struct StepValidator: Sendable {
    public var maximumTitleLength: Int

    public init(maximumTitleLength: Int = 80) {
        self.maximumTitleLength = maximumTitleLength
    }

    public func validate(_ document: StepDocument) -> StepValidationReport {
        var issues: [StepValidationIssue] = []
        let allSteps = document.steps

        if document.sections.isEmpty || allSteps.isEmpty {
            issues.append(issue(.error, .emptyDocument, "Document must contain at least one step.", "document.sections"))
        }

        var nowCount = 0
        var hasSeenTodoLikeState = false

        for (sectionIndex, section) in document.sections.enumerated() {
            let sectionPath = "document.sections[\(sectionIndex)]"
            if section.steps.isEmpty {
                issues.append(issue(.error, .emptySection, "Section must contain at least one step.", "\(sectionPath).steps"))
            }

            for (stepIndex, step) in section.steps.enumerated() {
                let stepPath = "\(sectionPath).steps[\(stepIndex)]"
                let title = StepNormalizer.collapseWhitespace(in: step.title).trimmingCharacters(in: .whitespacesAndNewlines)
                let searchableText = [step.title, step.detail].compactMap { $0 }.joined(separator: " ")

                if title.isEmpty {
                    issues.append(issue(.error, .emptyTitle, "Step title must not be empty.", "\(stepPath).title"))
                }

                if title.count > maximumTitleLength {
                    issues.append(issue(.warning, .overlongTitle, "Step title is longer than \(maximumTitleLength) characters.", "\(stepPath).title"))
                }

                if stepIndex > 0 {
                    let previous = section.steps[stepIndex - 1]
                    if duplicateKey(previous) == duplicateKey(step) {
                        issues.append(issue(.warning, .adjacentDuplicateStep, "Adjacent steps appear to be duplicates.", stepPath))
                    }
                }

                if containsObviousMultiAction(in: searchableText) {
                    issues.append(issue(.warning, .multiActionStep, "Step may contain multiple actions that should be split.", stepPath))
                }

                if containsAmbiguousDuration(in: searchableText) {
                    issues.append(issue(.warning, .ambiguousDuration, "Duration wording is ambiguous and should not be converted to an exact timer.", stepPath))
                }

                if containsModelCommentary(in: searchableText) {
                    issues.append(issue(.error, .modelCommentaryLeakage, "Step appears to contain model commentary or wrapped JSON.", stepPath))
                }

                if shouldRequireTimer(step: step, text: searchableText) {
                    issues.append(issue(.warning, .missingTimer, "Step has clear timer wording but no timer.", "\(stepPath).timer"))
                }

                if step.state == .now {
                    nowCount += 1
                }

                if step.state == .todo || step.state == .now {
                    hasSeenTodoLikeState = true
                } else if hasSeenTodoLikeState, step.state == .done {
                    issues.append(issue(.warning, .invalidStateOrdering, "Done steps should not appear after pending steps in a linear flow.", "\(stepPath).state"))
                }
            }
        }

        if nowCount > 1 {
            issues.append(issue(.error, .invalidStateOrdering, "Only one step can be marked as current.", "document.sections"))
        }

        return StepValidationReport(issues: issues)
    }

    private func issue(
        _ severity: StepValidationSeverity,
        _ code: StepValidationCode,
        _ message: String,
        _ path: String
    ) -> StepValidationIssue {
        StepValidationIssue(severity: severity, code: code, message: message, path: path)
    }

    private func duplicateKey(_ step: Step) -> String {
        let text = [step.title, step.detail].compactMap { $0 }.joined(separator: " ")
        return StepNormalizer.collapseWhitespace(in: text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func containsObviousMultiAction(in text: String) -> Bool {
        let lowercased = text.lowercased()
        return lowercased.contains(" and then ")
            || lowercased.contains("; then ")
            || lowercased.contains(". then ")
    }

    private func containsAmbiguousDuration(in text: String) -> Bool {
        let lowercased = text.lowercased()
        return lowercased.range(of: #"\b\d+\s*[-–]\s*\d+\s*(sec|secs|seconds?|min|mins|minutes?|hr|hrs|hours?)\b"#, options: .regularExpression) != nil
            || lowercased.contains("a while")
            || lowercased.contains("some time")
            || lowercased.contains("few minutes")
            || lowercased.contains("a few")
            || lowercased.contains("several ")
            || lowercased.contains("until ready")
            || lowercased.contains("overnight or")
    }

    private func containsModelCommentary(in text: String) -> Bool {
        let lowercased = text.lowercased()
        return lowercased.contains("```")
            || lowercased.contains("as an ai")
            || lowercased.contains("json:")
            || lowercased.range(of: #"\bi cannot (assist|comply|fulfill|generate|help|provide|answer)\b"#, options: .regularExpression) != nil
    }

    private func shouldRequireTimer(step: Step, text: String) -> Bool {
        guard step.timer == nil else {
            return false
        }

        let parsedDuration = StepNormalizer.parseDuration(from: text)

        if step.kind == .timer {
            return step.duration?.isExact == true || parsedDuration?.isExact == true
        }

        return (step.kind == .wait || containsTimerLikeInstruction(in: text))
            && (step.duration?.isExact == true || parsedDuration?.isExact == true)
    }

    private func containsTimerLikeInstruction(in text: String) -> Bool {
        let lowercased = StepNormalizer.collapseWhitespace(in: text).lowercased()
        return lowercased.hasPrefix("wait ")
            || lowercased.hasPrefix("rest ")
            || lowercased.hasPrefix("cool ")
            || lowercased.hasPrefix("chill ")
            || lowercased.hasPrefix("soak ")
            || lowercased.hasPrefix("proof ")
            || lowercased.hasPrefix("let sit ")
            || lowercased.hasPrefix("let stand ")
            || lowercased.hasPrefix("set a timer ")
            || lowercased.contains(" set a timer ")
    }
}
