import SwiftUI
import StepwiseCore

#if DEBUG
enum StepwisePreviewSamples {
    static let document = StepDocument(
        title: "Sample checklist",
        sections: [
            StepSection(
                title: "Setup",
                steps: [
                    Step(id: "one", title: "Open the kit", detail: "Lay everything on a clean surface.", icon: StepIconHint(symbolName: "shippingbox"), state: .done),
                    Step(id: "two", title: "Connect the cable", detail: "Use the marked port.", icon: StepIconHint(symbolName: "cable.connector"), state: .now),
                    Step(id: "three", title: "Wait 30 sec", kind: .timer, duration: .seconds(30), timer: StepTimer(duration: .seconds(30)), icon: StepIconHint(symbolName: "timer"))
                ]
            )
        ]
    )
}

struct StepCardView_Previews: PreviewProvider {
    static var previews: some View {
        StepFlowView(document: StepwisePreviewSamples.document)
            .previewLayout(.sizeThatFits)
    }
}
#endif
