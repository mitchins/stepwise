import SwiftUI
public import StepwiseCore

public struct StepCompletionView: View {
    public var document: StepDocument
    public var theme: StepwiseTheme
    public var doneCount: Int
    public var skippedCount: Int
    public var actionTitle: String?
    public var action: (() -> Void)?

    public init(
        document: StepDocument,
        theme: StepwiseTheme = .standard,
        doneCount: Int? = nil,
        skippedCount: Int? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.document = document
        self.theme = theme
        self.doneCount = doneCount ?? document.steps.filter { $0.state == .done }.count
        self.skippedCount = skippedCount ?? document.steps.filter { $0.state == .skipped }.count
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 86, height: 86)
                .background(theme.done, in: Circle())
                .accessibilityHidden(true)

            Text("All done.")
                .font(.title.weight(.bold))

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(theme.tint)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: theme.cornerRadius + 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summary)
    }

    private var summary: String {
        let total = document.steps.count
        if skippedCount > 0 {
            return "\(doneCount) of \(total) done, \(skippedCount) skipped."
        }
        return "\(doneCount) of \(total) done."
    }
}
