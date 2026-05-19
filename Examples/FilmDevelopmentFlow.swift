import StepwiseCore
import StepwiseUI

let filmDevelopmentFlow = StepDocument(
    title: "Black-and-white film development",
    sections: [
        StepSection(
            title: "Develop",
            steps: [
                Step(title: "Load the tank", detail: "Keep the film in complete darkness.", kind: .warning, icon: StepIconHint(symbolName: "film")),
                Step(title: "Pour developer", detail: "Dilution 1+31 at 20 °C.", icon: StepIconHint(symbolName: "drop.fill")),
                Step(title: "Develop 9 min", detail: "Agitate for 10 sec each minute.", kind: .timer, duration: .minutes(9), timer: StepTimer(duration: .minutes(9)), icon: StepIconHint(symbolName: "timer"))
            ]
        ),
        StepSection(
            title: "Finish",
            steps: [
                Step(title: "Stop and fix", detail: "Follow the chemical maker's timing.", kind: .warning, icon: StepIconHint(symbolName: "exclamationmark.triangle")),
                Step(title: "Wash and dry", detail: "Use clean running water, then hang in a dust-free place.", icon: StepIconHint(symbolName: "drop"))
            ]
        )
    ]
)

let filmDevelopmentFlowView = StepFlowView(document: filmDevelopmentFlow)
