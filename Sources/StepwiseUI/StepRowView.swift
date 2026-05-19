import SwiftUI
public import StepwiseCore

public struct StepRowView: View {
    public var step: Step
    public var index: Int?
    public var total: Int?
    public var theme: StepwiseTheme
    public var showsDetail: Bool
    public var action: (() -> Void)?

    public init(
        step: Step,
        index: Int? = nil,
        total: Int? = nil,
        theme: StepwiseTheme = .standard,
        showsDetail: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.step = step
        self.index = index
        self.total = total
        self.theme = theme
        self.showsDetail = showsDetail
        self.action = action
    }

    public var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
            } else {
                content
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(StepwiseAccessibility.label(for: step, index: index, total: total))
    }

    private var content: some View {
        HStack(spacing: 14) {
            StepIconView(step: step, theme: theme)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.headline)
                    .foregroundStyle(step.state == .skipped ? .secondary : .primary)
                    .strikethrough(step.state == .skipped)
                    .lineLimit(2)

                if showsDetail, let detail = step.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }

            Spacer(minLength: 8)

            if !step.stepwiseBadgeText.isEmpty {
                Text(step.stepwiseBadgeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(badgeForeground)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(badgeBackground, in: Capsule())
            }
        }
        .frame(minHeight: 44)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(rowBackground)
        .contentShape(Rectangle())
    }

    private var rowBackground: some ShapeStyle {
        step.state == .now ? AnyShapeStyle(theme.tint.opacity(0.08)) : AnyShapeStyle(.clear)
    }

    private var badgeForeground: Color {
        switch step.state {
        case .todo:
            .secondary
        case .now:
            .white
        case .done:
            theme.done
        case .skipped:
            .secondary
        }
    }

    private var badgeBackground: Color {
        switch step.state {
        case .todo:
            .secondary.opacity(0.12)
        case .now:
            theme.tint
        case .done:
            theme.done.opacity(0.16)
        case .skipped:
            .secondary.opacity(0.12)
        }
    }
}
