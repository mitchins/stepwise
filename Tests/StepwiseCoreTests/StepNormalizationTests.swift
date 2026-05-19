import Testing
import StepwiseCore

@Test
func normalizationTrimsWhitespaceAndStepPrefixes() {
    let step = Step(title: "  Step 1:   BOIL   WATER  ", detail: "  Until   hot. ")
    let normalized = StepNormalizer().normalize(step)

    #expect(normalized.title == "Boil water")
    #expect(normalized.detail == "Until hot.")
}

@Test
func parsesSimpleDurations() {
    #expect(StepNormalizer.parseDuration(from: "Wait 30 sec") == .seconds(30))
    #expect(StepNormalizer.parseDuration(from: "Wait 30sec") == .seconds(30))
    #expect(StepNormalizer.parseDuration(from: "Rest 45 seconds") == .seconds(45))
    #expect(StepNormalizer.parseDuration(from: "Bake 5 min") == .minutes(5))
    #expect(StepNormalizer.parseDuration(from: "Bake 5min") == .minutes(5))
    #expect(StepNormalizer.parseDuration(from: "Wait 5 minutes") == .minutes(5))
    #expect(StepNormalizer.parseDuration(from: "Hold 1 hour") == .hours(1))
    #expect(StepNormalizer.parseDuration(from: "Hold 2 hours") == .hours(2))
    #expect(StepNormalizer.parseDuration(from: "Wait 2 hr") == .hours(2))
}

@Test
func classifiesObviousTimerAndWaitPhrases() {
    let timerStep = StepNormalizer().normalize(Step(title: "Wait 5 min"))
    let timerInstruction = StepNormalizer().normalize(Step(title: "Set a timer for 30 sec"))
    let waitStep = StepNormalizer().normalize(Step(title: "Rest overnight"))

    #expect(timerStep.kind == .timer)
    #expect(timerStep.timer?.duration == .minutes(5))
    #expect(timerInstruction.kind == .timer)
    #expect(timerInstruction.timer?.duration == .seconds(30))
    #expect(waitStep.kind == .wait)
    #expect(waitStep.duration == .textual("overnight"))
    #expect(waitStep.timer == nil)
}

@Test
func doesNotCreateFalsePrecisionForOvernightOrAmbiguousDurations() {
    let overnight = StepNormalizer.parseDuration(from: "Proof overnight")
    let range = StepNormalizer.parseDuration(from: "Bake 5-7 min")
    let approximate = StepNormalizer.parseDuration(from: "Cook for a few minutes")

    #expect(overnight == .textual("overnight"))
    #expect(overnight?.exactSeconds == nil)
    #expect(range == nil)
    #expect(approximate == nil)
}

@Test
func keepsActionDurationsWithoutAddingTimersWhenInstructionIsNotTimerLike() {
    let normalized = StepNormalizer().normalize(Step(title: "Bake 5 min"))

    #expect(normalized.kind == .action)
    #expect(normalized.duration == .minutes(5))
    #expect(normalized.timer == nil)
}
