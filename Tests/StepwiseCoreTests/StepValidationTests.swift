import Testing
import StepwiseCore

@Test
func validationCatchesEmptyDocument() {
    let report = StepValidator().validate(StepDocument(sections: []))

    #expect(!report.isValid)
    #expect(report.contains(.emptyDocument))
}

@Test
func validationCatchesEmptyTitleDuplicateAndLongTitle() {
    let longTitle = String(repeating: "A", count: 90)
    let document = StepDocument(
        sections: [
            StepSection(
                steps: [
                    Step(title: ""),
                    Step(title: "Heat the pan"),
                    Step(title: "Heat the pan"),
                    Step(title: longTitle)
                ]
            )
        ]
    )

    let report = StepValidator().validate(document)

    #expect(!report.isValid)
    #expect(report.contains(.emptyTitle))
    #expect(report.contains(.adjacentDuplicateStep))
    #expect(report.contains(.overlongTitle))
}

@Test
func validationCatchesEmptySectionAndMultipleCurrentSteps() {
    let document = StepDocument(
        sections: [
            StepSection(steps: []),
            StepSection(steps: [
                Step(title: "Start", state: .now),
                Step(title: "Continue", state: .now)
            ])
        ]
    )

    let report = StepValidator().validate(document)

    #expect(!report.isValid)
    #expect(report.contains(.emptySection))
    #expect(report.contains(.invalidStateOrdering))
}

@Test
func validationFlagsModelCommentaryLeakageAndMissingTimer() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(title: "Here is the JSON:", detail: "```json"),
                Step(title: "Wait 5 min", kind: .wait, duration: .minutes(5)),
                Step(title: "Set a timer for 30 sec")
            ])
        ]
    )

    let report = StepValidator().validate(document)

    #expect(!report.isValid)
    #expect(report.contains(.modelCommentaryLeakage))
    #expect(report.contains(.missingTimer))
}

@Test
func validationDoesNotTreatOrdinaryHereIsPhrasingAsModelCommentary() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(title: "Mark the spot", detail: "The key here is keeping the edge aligned.")
            ])
        ]
    )

    let report = StepValidator().validate(document)

    #expect(!report.contains(.modelCommentaryLeakage))
}

@Test
func validationDoesNotTreatOrdinaryICannotPhrasingAsModelCommentary() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(title: "Verify I cannot proceed without a code")
            ])
        ]
    )

    let report = StepValidator().validate(document)

    #expect(!report.contains(.modelCommentaryLeakage))
}

@Test
func validationFlagsAmbiguousDurationRangesWithoutInventingPrecision() {
    let document = StepDocument(
        sections: [
            StepSection(steps: [
                Step(title: "Bake 5-7 min"),
                Step(title: "Cook for a few minutes"),
                Step(title: "Leave overnight or until dry")
            ])
        ]
    )

    let report = StepValidator().validate(document)

    #expect(report.isValid)
    #expect(report.issues.filter { $0.code == .ambiguousDuration }.count == 3)
}
