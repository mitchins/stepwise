import StepwiseCore
import StepwiseUI

let genericChecklist = StepDocument(
    title: "Equipment setup",
    sections: [
        StepSection(
            title: "Prepare",
            steps: [
                    Step(title: "Open the kit", detail: "Place each item on a clean surface.", annotations: .init(icon: StepIconHint(symbolName: "shippingbox"))),
                    Step(title: "Connect the cable", detail: "Use the marked port.", annotations: .init(icon: StepIconHint(symbolName: "cable.connector"))),
                    Step(title: "Check the indicator", kind: .check, annotations: .init(icon: StepIconHint(symbolName: "checkmark.circle")))
            ]
        )
    ]
)

let genericChecklistView = StepFlowView(document: genericChecklist)
