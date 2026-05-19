import SwiftUI
public import StepwiseCore

public struct StepSectionHeaderView: View {
    public var title: String?
    public var subtitle: String?

    public init(title: String?, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }
}

public struct StepListView: View {
    public var document: StepDocument
    public var theme: StepwiseTheme
    public var onSelectStep: ((Step) -> Void)?

    public init(
        document: StepDocument,
        theme: StepwiseTheme = .standard,
        onSelectStep: ((Step) -> Void)? = nil
    ) {
        self.document = document
        self.theme = theme
        self.onSelectStep = onSelectStep
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(indexedSections, id: \.section.id) { item in
                if item.section.title != nil {
                    StepSectionHeaderView(title: item.section.title)
                }

                VStack(spacing: 0) {
                    ForEach(Array(item.section.steps.enumerated()), id: \.element.id) { localIndex, step in
                        StepRowView(
                            step: step,
                            index: item.startIndex + localIndex,
                            total: document.steps.count,
                            theme: theme,
                            action: onSelectStep.map { callback in { callback(step) } }
                        )

                        if localIndex < item.section.steps.count - 1 {
                            Divider().padding(.leading, 76)
                        }
                    }
                }
                .background(.background, in: RoundedRectangle(cornerRadius: theme.cornerRadius + 4, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius + 4, style: .continuous))
            }
        }
    }

    private var indexedSections: [(section: StepSection, startIndex: Int)] {
        var startIndex = 0
        return document.sections.map { section in
            defer { startIndex += section.steps.count }
            return (section, startIndex)
        }
    }
}
