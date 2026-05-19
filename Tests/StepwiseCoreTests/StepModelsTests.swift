import Foundation
import Testing
import StepwiseCore

@Test
func documentCodableRoundTrips() throws {
    let document = StepDocument(
        id: "doc",
        title: "Tomato butter curry",
        summary: "A short recipe flow.",
        sections: [
            StepSection(
                id: "prep",
                title: "Prep",
                steps: [
                    Step(
                        id: "rinse",
                        title: "Rinse the rice",
                        detail: "Cold water until it runs clear.",
                        kind: .action,
                        timing: .init(duration: .minutes(2)),
                        annotations: .init(
                            icon: StepIconHint(symbolName: "drop.fill"),
                            warnings: [StepWarning(id: "note", message: "Drain completely.")]
                        )
                    )
                ]
            )
        ],
        estimatedDuration: .minutes(38),
        metadata: ["source": "test"]
    )

    let encoded = try JSONEncoder().encode(document)
    let decoded = try JSONDecoder().decode(StepDocument.self, from: encoded)

    #expect(decoded == document)
}

@Test
func derivesCurrentStepFromConsumerOwnedState() {
    let document = StepDocument(
        id: "doc",
        sections: [
            StepSection(
                id: "main",
                steps: [
                    Step(id: "one", title: "Open the box"),
                    Step(id: "two", title: "Connect the cable"),
                    Step(id: "three", title: "Confirm setup")
                ]
            )
        ]
    )

    let current = document.currentStep(completedIDs: ["one"], skippedIDs: [])
    let states = document.stateMap(completedIDs: ["one"], skippedIDs: [], preferredActiveID: nil)
    let progress = document.progress(completedIDs: ["one"], skippedIDs: ["three"])

    #expect(current?.id == "two")
    #expect(states["one"] == .done)
    #expect(states["two"] == .now)
    #expect(states["three"] == .todo)
    #expect(progress.totalCount == 3)
    #expect(progress.doneCount == 1)
    #expect(progress.skippedCount == 1)
    #expect(progress.currentIndex == 1)
}

@Test
func derivesCurrentStepFromEmbeddedState() {
    let document = StepDocument(
        sections: [
            StepSection(
                steps: [
                    Step(id: "one", title: "Open", state: .done),
                    Step(id: "two", title: "Connect", state: .now),
                    Step(id: "three", title: "Confirm", state: .todo)
                ]
            )
        ]
    )

    #expect(document.currentStep?.id == "two")
    #expect(document.currentStepIndex == 1)
}

@Test
func stateMapDoesNotCrashOnDuplicateStepIDs() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "dup", title: "First"),
                Step(id: "dup", title: "Second"),
                Step(id: "third", title: "Third")
            ])
        ]
    )

    let states = document.stateMap(preferredActiveID: "third")

    #expect(states["dup"] == .todo)
    #expect(states["third"] == .now)
}

@Test
func preferredCurrentStepPreservesDoneAndSkippedStates() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "done", title: "Done", state: .done),
                Step(id: "todo", title: "Todo", state: .todo),
                Step(id: "skip", title: "Skip", state: .skipped)
            ])
        ]
    )

    let updated = document.preferringCurrentStep("todo")

    #expect(updated.steps[0].state == .done)
    #expect(updated.steps[1].state == .now)
    #expect(updated.steps[2].state == .skipped)
}

@Test
func preferredCurrentStepLeavesExistingStateUntouchedWhenPreferenceIsInvalid() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "done", title: "Done", state: .done),
                Step(id: "current", title: "Current", state: .now),
                Step(id: "todo", title: "Todo", state: .todo)
            ])
        ]
    )

    let updated = document.preferringCurrentStep("done")

    #expect(updated.steps.map(\.state) == [.done, .now, .todo])
}

@Test
func preferredCurrentStepUsesPositionToDisambiguateDuplicateIDs() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(id: "dup", title: "Finished", state: .done),
                Step(id: "dup", title: "Active", state: .todo),
                Step(id: "tail", title: "Tail", state: .todo)
            ])
        ]
    )

    let updated = document.preferringCurrentStep("dup")

    #expect(updated.steps.map(\.state) == [.done, .now, .todo])
}
