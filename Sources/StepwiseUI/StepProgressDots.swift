import SwiftUI

public struct StepProgressDots: View {
    public var total: Int
    public var currentIndex: Int
    public var completedCount: Int
    public var theme: StepwiseTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        total: Int,
        currentIndex: Int,
        completedCount: Int = 0,
        theme: StepwiseTheme = .standard
    ) {
        self.total = total
        self.currentIndex = currentIndex
        self.completedCount = completedCount
        self.theme = theme
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(total, 0), id: \.self) { index in
                Capsule()
                    .fill(color(for: index))
                    .frame(width: index == currentIndex ? 22 : 8, height: 8)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.26), value: currentIndex)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        let announcedTotal = max(total, 1)
        let announcedIndex = min(max(currentIndex + 1, 1), announcedTotal)
        return "Step \(announcedIndex) of \(announcedTotal)"
    }

    private func color(for index: Int) -> Color {
        if index < completedCount {
            return theme.done
        }
        if index == currentIndex {
            return theme.tint
        }
        return .secondary.opacity(0.28)
    }
}
