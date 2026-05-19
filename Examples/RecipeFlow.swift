import StepwiseCore
import StepwiseUI

let recipeFlow = StepDocument(
    title: "Tomato rice",
    summary: "A small recipe flow.",
    sections: [
        StepSection(
            title: "Prep",
            steps: [
                    Step(title: "Rinse the rice", detail: "Cold water until it runs clear.", timing: .init(duration: .minutes(2)), annotations: .init(icon: StepIconHint(symbolName: "drop.fill"))),
                    Step(title: "Chop the tomatoes", detail: "Keep the juices.", annotations: .init(icon: StepIconHint(symbolName: "knife")))
            ]
        ),
        StepSection(
            title: "Cook",
            steps: [
                    Step(title: "Heat the pan", detail: "Medium heat.", timing: .init(duration: .minutes(3)), annotations: .init(icon: StepIconHint(symbolName: "flame.fill"))),
                    Step(title: "Simmer 20 min", detail: "Low heat, covered. Stir every 5 min.", kind: .timer, timing: .init(duration: .minutes(20), timer: StepTimer(duration: .minutes(20))), annotations: .init(icon: StepIconHint(symbolName: "timer")))
            ]
        )
    ],
    estimatedDuration: .minutes(30)
)

let recipeFlowView = StepFlowView(document: recipeFlow)
