import StepwiseCore
import StepwiseUI

let filmDevelopmentFlow = StepDocument(
    title: "Black-and-white film development",
    sections: [
        StepSection(
            title: "Develop",
            steps: [
                    Step(title: "Load the tank", detail: "Keep the film in complete darkness.", kind: .warning, annotations: .init(icon: StepIconHint(symbolName: "film"))),
                    Step(title: "Pour developer", detail: "Dilution 1+31 at 20 °C.", annotations: .init(icon: StepIconHint(symbolName: "drop.fill"))),
                    Step(title: "Develop 9 min", detail: "Agitate for 10 sec each minute.", kind: .timer, timing: .init(duration: .minutes(9), timer: StepTimer(duration: .minutes(9))), annotations: .init(icon: StepIconHint(symbolName: "timer")))
            ]
        ),
        StepSection(
            title: "Finish",
            steps: [
                    Step(title: "Stop and fix", detail: "Follow the chemical maker's timing.", kind: .warning, annotations: .init(icon: StepIconHint(symbolName: "exclamationmark.triangle"))),
                    Step(title: "Wash and dry", detail: "Use clean running water, then hang in a dust-free place.", annotations: .init(icon: StepIconHint(symbolName: "drop")))
            ]
        )
    ]
)

let filmDevelopmentFlowView = StepFlowView(document: filmDevelopmentFlow)
