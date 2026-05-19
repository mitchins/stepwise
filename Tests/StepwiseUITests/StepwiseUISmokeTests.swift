import Testing
import StepwiseCore
@testable import StepwiseUI

@MainActor
@Test
func viewInitializersCompileWithCoreModels() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "one", title: "Open the kit", state: .done),
                Step(id: "two", title: "Check the setup", detail: "Confirm each item is present.", state: .now)
            ])
        ]
    )
    let step = document.steps[1]

    _ = StepCardView(step: step, index: 1, total: 2)
    _ = StepRowView(step: step, index: 1, total: 2)
    _ = StepListView(document: document)
    _ = StepFlowView(document: document)
    _ = StepProgressDots(total: 2, currentIndex: 1, completedCount: 1)
    _ = StepSectionHeaderView(title: "Setup")
    _ = StepCompletionView(document: document)
    _ = StepRailView(document: document)
    _ = WatchStepRailView(document: document)

    #expect(step.title == "Check the setup")
}

@Test
func accessibilityLabelIncludesPositionTitleDetailAndState() {
    let step = Step(title: "Check the setup", detail: "Confirm each item is present.", state: .now)
    let label = StepwiseAccessibility.label(for: step, index: 1, total: 3)

    #expect(label == "Step 2 of 3, Check the setup, Confirm each item is present., Now")
}

@MainActor
@Test
func flowViewDoesNotExposeCompletedCurrentStepAsActive() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "done", title: "Finished", state: .done)
            ])
        ]
    )

    let view = StepFlowView(document: document, currentStepID: "done")

    #expect(view.activeStep == nil)
}

@MainActor
@Test
func watchRailUsesDisplayDocumentStates() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "a", title: "First", state: .now),
                Step(id: "b", title: "Second", state: .todo)
            ])
        ]
    )

    let view = WatchStepRailView(document: document, currentStepID: "b")

    #expect(view.railSteps[0].state == .todo)
    #expect(view.railSteps[1].state == .now)
}

@MainActor
@Test
func watchRailDoesNotExposeCompletedCurrentStepAsActive() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "done", title: "Finished", state: .done)
            ])
        ]
    )

    let view = WatchStepRailView(document: document, currentStepID: "done")

    #expect(view.railSteps[0].state == .done)
}
