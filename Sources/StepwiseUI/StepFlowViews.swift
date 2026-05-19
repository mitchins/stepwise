import SwiftUI
public import StepwiseCore

public struct StepRailView: View {
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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(Array(document.steps.enumerated()), id: \.element.id) { index, step in
                    StepRowView(
                        step: step,
                        index: index,
                        total: document.steps.count,
                        theme: theme,
                        showsDetail: false,
                        action: onSelectStep.map { callback in { callback(step) } }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
    }
}

public struct StepFlowView: View {
    public var document: StepDocument
    public var currentStepID: Step.ID?
    public var theme: StepwiseTheme
    public var onSelectStep: ((Step) -> Void)?
    public var onMarkDone: ((Step) -> Void)?

    public init(
        document: StepDocument,
        currentStepID: Step.ID? = nil,
        theme: StepwiseTheme = .standard,
        onSelectStep: ((Step) -> Void)? = nil,
        onMarkDone: ((Step) -> Void)? = nil
    ) {
        self.document = document
        self.currentStepID = currentStepID
        self.theme = theme
        self.onSelectStep = onSelectStep
        self.onMarkDone = onMarkDone
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 20) {
                StepRailView(document: displayDocument, theme: theme, onSelectStep: onSelectStep)
                    .frame(width: 320)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))

                activeColumn
                    .frame(maxWidth: 620)
            }

            VStack(alignment: .leading, spacing: theme.spacing) {
                activeColumn
                StepListView(document: displayDocument, theme: theme, onSelectStep: onSelectStep)
            }
        }
        .padding(theme.spacing)
    }

    private var activeColumn: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            if let activeStep, let activeIndex {
                StepCardView(
                    step: activeStep,
                    index: activeIndex,
                    total: document.steps.count,
                    theme: theme,
                    actionTitle: onMarkDone == nil ? nil : "Mark as done",
                    action: onMarkDone.map { callback in { callback(activeStep) } }
                )

                StepProgressDots(
                    total: document.steps.count,
                    currentIndex: activeIndex,
                    completedCount: document.steps.filter { $0.state == .done }.count,
                    theme: theme
                )
            } else {
                StepCompletionView(document: document, theme: theme)
            }
        }
    }

    var displayDocument: StepDocument {
        document.preferringCurrentStep(currentStepID)
    }

    var activeStep: Step? {
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
}

public typealias StepPagerView = StepFlowView
