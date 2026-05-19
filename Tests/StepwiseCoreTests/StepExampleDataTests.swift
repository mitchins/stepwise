import Testing
import StepwiseCore

@Test
func recipeAndFilmExampleShapesValidate() {
    let recipe = StepDocument(
        title: "Tomato rice",
        sections: [
            StepSection(title: "Cook", steps: [
                Step(title: "Rinse the rice"),
                Step(title: "Simmer 20 min", kind: .timer, timing: .init(duration: .minutes(20), timer: StepTimer(duration: .minutes(20))))
            ])
        ]
    )

    let film = StepDocument(
        title: "Black-and-white film development",
        sections: [
            StepSection(title: "Develop", steps: [
                Step(title: "Pour developer", detail: "Dilution 1+31 at 20 °C."),
                Step(title: "Develop 9 min", detail: "Agitate for 10 sec each minute.", kind: .timer, timing: .init(duration: .minutes(9), timer: StepTimer(duration: .minutes(9))))
            ])
        ]
    )

    #expect(StepValidator().validate(recipe).isValid)
    #expect(StepValidator().validate(film).isValid)
}
