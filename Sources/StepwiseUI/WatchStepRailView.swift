import SwiftUI
public import StepwiseCore

public struct WatchStepRailView: View {
    public var document: StepDocument
    public var currentStepID: Step.ID?
    public var theme: StepwiseTheme
    public var onSelectStep: ((Step) -> Void)?

    public init(
        document: StepDocument,
        currentStepID: Step.ID? = nil,
        theme: StepwiseTheme = .watch,
        onSelectStep: ((Step) -> Void)? = nil
    ) {
        self.document = document
        self.currentStepID = currentStepID
        self.theme = theme
        self.onSelectStep = onSelectStep
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if document.steps.isEmpty {
                Text("No steps")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            } else if let activeStep, let activeIndex {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Now · \(activeIndex + 1) of \(document.steps.count)")
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(theme.warning)

                    Text(activeStep.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(.regularMaterial)
            }

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(railSteps.enumerated()), id: \.offset) { index, step in
                        StepRowView(
                            step: step,
                            index: index,
                            total: railSteps.count,
                            theme: theme,
                            showsDetail: false,
                            action: onSelectStep.map { callback in { callback(step) } }
                        )
                        .font(.caption)
                    }
                }
            }
        }
    }

    private var displayDocument: StepDocument {
        document.preferringCurrentStep(currentStepID)
    }

    private var activeStep: Step? {
        displayDocument.currentStep
    }

    var activeIndex: Int? {
        displayDocument.currentStepIndex
    }

    var railSteps: [Step] {
        displayDocument.steps
    }
}
