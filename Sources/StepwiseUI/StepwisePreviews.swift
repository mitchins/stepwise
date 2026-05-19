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
                    Step(id: "one", title: "Open the kit", detail: "Lay everything on a clean surface.", state: .done, annotations: .init(icon: StepIconHint(symbolName: "shippingbox"))),
                    Step(id: "two", title: "Connect the cable", detail: "Use the marked port.", state: .now, annotations: .init(icon: StepIconHint(symbolName: "cable.connector"))),
                    Step(id: "three", title: "Wait 30 sec", kind: .timer, timing: .init(duration: .seconds(30), timer: StepTimer(duration: .seconds(30))), annotations: .init(icon: StepIconHint(symbolName: "timer")))
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
