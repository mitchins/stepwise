import Foundation

public struct StepNormalizer: Sendable {
    public enum SentenceCasePolicy: Sendable {
        case preserve
        case safe
    }

    public var sentenceCasePolicy: SentenceCasePolicy

    public init(sentenceCasePolicy: SentenceCasePolicy = .safe) {
        self.sentenceCasePolicy = sentenceCasePolicy
    }

    public func normalize(_ document: StepDocument) -> StepDocument {
        var normalized = document
        normalized.title = normalizeOptionalText(document.title)
        normalized.summary = normalizeOptionalText(document.summary)
        normalized.sections = document.sections.map(normalize(_:))
        return normalized
    }

    public func normalize(_ section: StepSection) -> StepSection {
        var normalized = section
        normalized.title = normalizeOptionalText(section.title)
        normalized.steps = section.steps.map(normalize(_:))
        return normalized
    }

    public func normalize(_ step: Step) -> Step {
        var normalized = step
        normalized.title = normalizeTitle(step.title)
        normalized.detail = normalizeOptionalText(step.detail)

        let text = [normalized.title, normalized.detail].compactMap { $0 }.joined(separator: " ")
        if normalized.duration == nil {
            normalized.duration = Self.parseDuration(from: text)
        }

        normalized.kind = normalizedKind(for: normalized, text: text)

        if normalized.kind == .timer, normalized.timer == nil, let duration = normalized.duration, duration.isExact {
            normalized.timer = StepTimer(title: normalized.title, duration: duration)
        }

        return normalized
    }

    public func normalizeTitle(_ title: String) -> String {
        let withoutPrefix = Self.removeStepPrefix(from: title)
        let collapsed = Self.collapseWhitespace(in: withoutPrefix).trimmingCharacters(in: .whitespacesAndNewlines)
        guard sentenceCasePolicy == .safe else {
            return collapsed
        }
        return Self.safeSentenceCase(collapsed)
    }

    public func normalizeOptionalText(_ text: String?) -> String? {
        guard let text else {
            return nil
        }
        let collapsed = Self.collapseWhitespace(in: text).trimmingCharacters(in: .whitespacesAndNewlines)
        return collapsed.isEmpty ? nil : collapsed
    }

    public static func collapseWhitespace(in text: String) -> String {
        text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    static func containsObviousMultiAction(in text: String) -> Bool {
        let lowercased = collapseWhitespace(in: text).lowercased()
        return lowercased.contains(" and then ")
            || lowercased.contains("; then ")
            || lowercased.contains(". then ")
    }

    static func containsAmbiguousDuration(in text: String) -> Bool {
        let lowercased = collapseWhitespace(in: text).lowercased()
        return lowercased.range(of: #"\b\d+\s*[-–]\s*\d+\s*(sec|secs|seconds?|min|mins|minutes?|hr|hrs|hours?)\b"#, options: .regularExpression) != nil
            || lowercased.contains("a while")
            || lowercased.contains("some time")
            || lowercased.contains("few minutes")
            || lowercased.contains("a few")
            || lowercased.contains("several ")
            || lowercased.contains("until ready")
            || lowercased.contains("overnight or")
    }

    static func containsTimerLikeInstruction(in text: String) -> Bool {
        let lowercased = collapseWhitespace(in: text).lowercased()
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

    public static func removeStepPrefix(from text: String) -> String {
        text.replacingOccurrences(
            of: #"^\s*(?:step\s*)?\d+\s*(?:[.):]|-\s+)\s*"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    public static func parseDuration(from text: String) -> StepDuration? {
        let normalized = collapseWhitespace(in: text).lowercased()

        if normalized.contains("overnight") {
            return .textual("overnight")
        }

        if Self.containsAmbiguousDuration(in: normalized) {
            return nil
        }

        guard let match = normalized.range(
            of: #"(?<![\d\-])(\d+)\s*(seconds?|secs?|sec|s|minutes?|mins?|min|m|hours?|hrs?|hr|h)\b"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let token = String(normalized[match])
        let digitPrefix = token.prefix(while: \.isNumber)
        guard let value = Int(digitPrefix) else {
            return nil
        }

        let unit = token.dropFirst(digitPrefix.count).trimmingCharacters(in: .whitespacesAndNewlines)

        if ["s", "sec", "secs", "second", "seconds"].contains(unit) {
            return .seconds(value)
        }

        if ["m", "min", "mins", "minute", "minutes"].contains(unit) {
            return .minutes(value)
        }

        if ["h", "hr", "hrs", "hour", "hours"].contains(unit) {
            return .hours(value)
        }

        return nil
    }

    private func normalizedKind(for step: Step, text: String) -> StepKind {
        guard step.kind == .action || step.kind == .wait else {
            return step.kind
        }

        guard Self.containsTimerLikeInstruction(in: text) else {
            return step.kind
        }

        if step.duration?.isExact == true {
            return .timer
        }

        return .wait
    }

    private static func safeSentenceCase(_ text: String) -> String {
        guard !text.isEmpty else {
            return text
        }

        let letters = text.filter(\.isLetter)
        if !letters.isEmpty, letters.allSatisfy(\.isUppercase) {
            let lowercased = text.lowercased()
            return lowercased.prefix(1).uppercased() + lowercased.dropFirst()
        }

        return text
    }

}
