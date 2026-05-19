import SwiftUI
import Testing
import StepwiseCore
@testable import StepwiseUI

@MainActor
private func exerciseView<V: View>(_ view: V) {
    _ = view.body
}

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

@MainActor
@Test
func rendersCardRowProgressAndThemeBodies() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "done", title: "Open the kit", detail: "Lay everything on a clean surface.", state: .done),
                Step(id: "now", title: "Connect the cable", detail: "Use the marked port.", state: .now),
                Step(id: "skip", title: "Skip this step", detail: "Optional.", state: .skipped),
                Step(id: "todo", title: "Wait 30 sec", kind: .timer, timing: .init(duration: .seconds(30), timer: StepTimer(duration: .seconds(30))))
            ])
        ]
    )

    exerciseView(StepIconView(step: document.steps[0], theme: .standard, size: 48))
    exerciseView(StepIconView(step: document.steps[1], theme: .watch, size: 48))
    exerciseView(StepCardView(step: document.steps[1], index: 1, total: document.steps.count, theme: .standard, actionTitle: "Mark as done", action: {}))
    exerciseView(StepCardView(step: document.steps[0], index: 0, total: document.steps.count, theme: .standard))
    exerciseView(StepRowView(step: document.steps[2], index: 2, total: document.steps.count, theme: .standard, showsDetail: true, action: {}))
    exerciseView(StepRowView(step: document.steps[3], index: 3, total: document.steps.count, theme: .watch, showsDetail: false))
    exerciseView(StepProgressDots(total: document.steps.count, currentIndex: -1, completedCount: 1, theme: .standard))

    let theme = StepwiseTheme.standard
    _ = theme.color(for: .todo)
    _ = theme.color(for: .now)
    _ = theme.color(for: .done)
    _ = theme.color(for: .skipped)
    _ = theme.foregroundColor(for: .todo)
    _ = theme.foregroundColor(for: .now)
    _ = theme.foregroundColor(for: .done)
    _ = theme.foregroundColor(for: .skipped)

    #expect(StepwiseAccessibility.label(for: document.steps[1], index: 1, total: 4) == "Step 2 of 4, Connect the cable, Use the marked port., Now")
}

@MainActor
@Test
func rendersListAndFlowBodies() {
    let document = StepDocument(
        sections: [
            StepSection(
                title: "Setup",
                steps: [
                    Step(id: "done", title: "Open the kit", detail: "Lay everything on a clean surface.", state: .done),
                    Step(id: "now", title: "Connect the cable", detail: "Use the marked port.", state: .now)
                ]
            ),
            StepSection(
                steps: [
                    Step(id: "skip", title: "Skip this step", detail: "Optional.", state: .skipped),
                    Step(id: "todo", title: "Wait 30 sec", kind: .timer, timing: .init(duration: .seconds(30), timer: StepTimer(duration: .seconds(30))))
                ]
            )
        ]
    )

    let completedDocument = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "finished", title: "Finished", state: .done)
            ])
        ]
    )

    exerciseView(StepListView(document: document, theme: .standard, onSelectStep: { _ in }))
    exerciseView(StepListView(document: document, theme: .standard))
    exerciseView(StepFlowView(document: document, currentStepID: "now", theme: .standard, onSelectStep: { _ in }, onMarkDone: { _ in }))
    exerciseView(StepFlowView(document: completedDocument, currentStepID: "finished", theme: .watch))
}

@MainActor
@Test
func rendersCompletionAndWatchBodies() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "a", title: "First", state: .now),
                Step(id: "b", title: "Second", state: .todo)
            ])
        ]
    )

    let completedDocument = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "finished", title: "Finished", state: .done)
            ])
        ]
    )

    exerciseView(StepCompletionView(document: completedDocument, theme: .standard, actionTitle: "Continue", action: {}))
    exerciseView(StepCompletionView(document: completedDocument, theme: .standard))
    exerciseView(WatchStepRailView(document: document, currentStepID: "a", theme: .watch, onSelectStep: { _ in }))
    exerciseView(WatchStepRailView(document: StepDocument(sections: []), theme: .watch))
}

@MainActor
@Test
func readsPreviewSampleDocument() {
    let preview = StepwisePreviewSamples.document

    #expect(preview.steps.count == 3)
    #expect(preview.steps[1].state == .now)
}

@MainActor
@Test
func flowViewResolvesDuplicateIDsByPositionWhenRendered() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "dup", title: "Finished", state: .done),
                Step(id: "dup", title: "Active", state: .todo),
                Step(id: "tail", title: "Tail", state: .todo)
            ])
        ]
    )

    let view = StepFlowView(document: document, currentStepID: "dup")

    #expect(view.displayDocument.steps.map(\.state) == [.done, .now, .todo])
    #expect(view.activeIndex == 1)
    exerciseView(view)
}
