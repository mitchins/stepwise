import SwiftUI
public import StepwiseCore

public enum StepIconStyle: Sendable {
    case tile
    case bare
}

public struct StepwiseTheme: Sendable {
    public var tint: Color
    public var done: Color
    public var warning: Color
    public var skipped: Color
    public var cornerRadius: CGFloat
    public var spacing: CGFloat
    public var iconStyle: StepIconStyle

    public init(
        tint: Color = .indigo,
        done: Color = .green,
        warning: Color = .orange,
        skipped: Color = .secondary,
        cornerRadius: CGFloat = 18,
        spacing: CGFloat = 16,
        iconStyle: StepIconStyle = .tile
    ) {
        self.tint = tint
        self.done = done
        self.warning = warning
        self.skipped = skipped
        self.cornerRadius = cornerRadius
        self.spacing = spacing
        self.iconStyle = iconStyle
    }

    public static let standard = StepwiseTheme()
    public static let watch = StepwiseTheme(cornerRadius: 12, spacing: 10, iconStyle: .bare)
}

public enum StepwiseAccessibility {
    public static func label(for step: Step, index: Int? = nil, total: Int? = nil) -> String {
        var parts: [String] = []
        if let index, let total {
            parts.append("Step \(index + 1) of \(total)")
        }
        parts.append(step.title)
        if let detail = step.detail, !detail.isEmpty {
            parts.append(detail)
        }
        parts.append(label(for: step.state))
        return parts.joined(separator: ", ")
    }

    public static func label(for state: StepState) -> String {
        switch state {
        case .todo:
            "To do"
        case .now:
            "Now"
        case .done:
            "Done"
        case .skipped:
            "Skipped"
        }
    }
}

extension Step {
    var stepwiseSymbolName: String {
        if state == .done {
            return "checkmark"
        }

        if state == .skipped {
            return "forward.end.fill"
        }

        if state == .now {
            return icon?.symbolName ?? "circle.dashed"
        }

        if let icon {
            return icon.symbolName
        }

        switch kind {
        case .action:
            return "circle"
        case .wait:
            return "clock"
        case .timer:
            return "timer"
        case .check:
            return "checkmark.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .complete:
            return "checkmark.seal"
        }
    }

    var stepwiseBadgeText: String {
        switch state {
        case .todo:
            duration?.description ?? ""
        case .now:
            "Now"
        case .done:
            "Done"
        case .skipped:
            "Skipped"
        }
    }
}

extension StepwiseTheme {
    func color(for state: StepState) -> Color {
        switch state {
        case .todo:
            .secondary
        case .now:
            tint
        case .done:
            done
        case .skipped:
            skipped
        }
    }

    func foregroundColor(for state: StepState) -> Color {
        switch state {
        case .todo:
            .primary
        case .now, .done:
            .white
        case .skipped:
            .primary
        }
    }
}
