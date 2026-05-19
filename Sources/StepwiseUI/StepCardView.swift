import SwiftUI
public import StepwiseCore

public struct StepCardView: View {
    public var step: Step
    public var index: Int?
    public var total: Int?
    public var theme: StepwiseTheme
    public var actionTitle: String?
    public var action: (() -> Void)?

    public init(
        step: Step,
        index: Int? = nil,
        total: Int? = nil,
        theme: StepwiseTheme = .standard,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.step = step
        self.index = index
        self.total = total
        self.theme = theme
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            HStack(alignment: .top) {
                StepIconView(step: step, theme: theme, size: 48)

                Spacer()

                if let index, let total {
                    Text("Step \(index + 1) of \(total)")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail = step.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(theme.tint)
                    .controlSize(.large)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: theme.cornerRadius + 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius + 10, style: .continuous)
                .strokeBorder(.separator.opacity(0.35))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(StepwiseAccessibility.label(for: step, index: index, total: total))
    }
}
