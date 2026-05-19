import SwiftUI
import StepwiseCore

struct StepIconView: View {
    let step: Step
    let theme: StepwiseTheme
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: step.stepwiseSymbolName)
            .font(.system(size: max(16, size * 0.5), weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(foregroundStyle)
            .frame(width: size, height: size)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: max(8, size * 0.32), style: .continuous))
            .accessibilityHidden(true)
    }

    private var foregroundStyle: Color {
        switch theme.iconStyle {
        case .tile:
            step.state == .todo ? theme.color(for: step.state) : theme.foregroundColor(for: step.state)
        case .bare:
            theme.color(for: step.state)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch theme.iconStyle {
        case .tile:
            if step.state == .todo {
                RoundedRectangle(cornerRadius: max(8, size * 0.32), style: .continuous)
                    .fill(.secondary.opacity(0.14))
            } else {
                RoundedRectangle(cornerRadius: max(8, size * 0.32), style: .continuous)
                    .fill(theme.color(for: step.state))
            }
        case .bare:
            Color.clear
        }
    }
}
