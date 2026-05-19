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
                    ForEach(Array(railSteps.enumerated()), id: \.element.id) { index, step in
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
        currentStepID.flatMap { id in
            guard let step = displayDocument.step(withID: id),
                  step.state != .done,
                  step.state != .skipped else {
                return nil
            }
            return step
        } ?? displayDocument.currentStep
    }

    private var activeIndex: Int? {
        guard let activeStep else {
            return nil
        }
        return displayDocument.steps.firstIndex { $0.id == activeStep.id }
    }

    var railSteps: [Step] {
        displayDocument.steps
    }
}
