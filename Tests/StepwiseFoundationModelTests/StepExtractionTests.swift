import Testing
import StepwiseCore
import StepwiseFoundationModel

@Test
func promptBuilderRequiresStrictJSON() {
    let prompts = StepPromptSet.build(input: "Open the box. Check the cable.")

    #expect(prompts.system.contains("Return strict JSON only"))
    #expect(prompts.system.contains("No prose"))
    #expect(prompts.schema.description.contains("StepDocument"))
}

@Test
func configurationClampsMaximumTitleLengthToAtLeastOneCharacter() {
    let configuration = StepExtractionConfiguration(maximumRepairAttempts: -2, maximumTitleLength: 0)

    #expect(configuration.maximumRepairAttempts == 0)
    #expect(configuration.maximumTitleLength == 1)
}

@Test
func recipePromptPreservesMeasurements() {
    let prompts = StepPromptSet.build(
        input: "Bake at 180 °C for 25 min.",
        configuration: StepExtractionConfiguration(domain: .recipe)
    )

    #expect(prompts.system.contains("Preserve measurements"))
    #expect(prompts.system.contains("temperatures"))
    #expect(prompts.system.contains("baking"))
}

@Test
func filmPromptPreservesTimingsAgitationAndTemperature() {
    let prompts = StepPromptSet.build(
        input: "Develop 9 min at 20 °C. Agitate 10 sec each minute. Dilution 1+31.",
        configuration: StepExtractionConfiguration(domain: .filmDevelopment)
    )

    #expect(prompts.system.contains("timings"))
    #expect(prompts.system.contains("agitation cadence"))
    #expect(prompts.system.contains("dilution"))
    #expect(prompts.system.contains("temperature"))
}

@Test
func parserAcceptsValidJSONAndRunsValidation() throws {
    let result = try StepExtractionParser().parse(validJSON)

    #expect(result.document.title == "Checklist")
    #expect(result.document.steps.count == 2)
    #expect(result.validationReport.isValid)
    #expect(result.document.steps[1].kind == .timer)
    #expect(result.document.steps[1].timer?.duration == .minutes(5))
}

@Test
func parserRejectsCommentaryWrappedJSONByDefault() {
    #expect(throws: StepExtractionError.commentaryWrappedJSON) {
        try StepExtractionParser().parse("Here is the JSON:\n\(validJSON)")
    }
}

@Test
func parserTreatsTruncatedJSONAsInvalidJSON() {
    #expect(throws: StepExtractionError.invalidJSON("Output is not a JSON object.")) {
        try StepExtractionParser().parse("""
        {
          "title": "Checklist"
        """)
    }
}

@Test
func parserCanStripWrappedJSONOnlyWhenExplicitlyConfigured() throws {
    let parser = StepExtractionParser(
        configuration: StepExtractionConfiguration(allowsSafeJSONExtraction: true)
    )

    let result = try parser.parse("Here is the JSON:\n\(validJSON)")

    #expect(result.document.steps.count == 2)
}

@Test
func parserRejectsInvalidDocumentsAfterValidation() {
    let invalid = """
    {
      "title": "Bad",
      "sections": [
        {"steps": [{"title": ""}]}
      ]
    }
    """

    do {
        _ = try StepExtractionParser().parse(invalid)
        Issue.record("Expected validation failure")
    } catch StepExtractionError.validationFailed(let report) {
        #expect(report.contains(.emptyTitle))
    } catch {
        Issue.record("Expected validation failure, got \(error)")
    }
}

@Test
func parserConsumesConfiguredRepairOutputs() throws {
    let invalid = """
    {
      "title": "Bad",
      "sections": [
        {"steps": [{"title": ""}]}
      ]
    }
    """

    let parser = StepExtractionParser(
        configuration: StepExtractionConfiguration(maximumRepairAttempts: 1)
    )

    let result = try parser.parse(
        invalid,
        originalInput: "1. Open the box.\n2. Wait 5 min.",
        repairOutputs: [validJSON]
    )

    #expect(result.validationReport.isValid)
    #expect(result.document.title == "Checklist")
    #expect(result.repairs.count == 1)
    #expect(result.repairs[0].validationReport?.contains(.emptyTitle) == true)
    #expect(result.repairs[0].prompt.contains("Repair the JSON output"))
}

@Test
func parserHonorsRepairAttemptLimit() {
    let invalid = """
    {
      "title": "Bad",
      "sections": [
        {"steps": [{"title": ""}]}
      ]
    }
    """

    let parser = StepExtractionParser(
        configuration: StepExtractionConfiguration(maximumRepairAttempts: 0)
    )

    #expect(throws: StepExtractionError.validationFailed(StepValidationReport(issues: [
        StepValidationIssue(severity: .error, code: .emptyTitle, message: "Step title must not be empty.", path: "document.sections[0].steps[0].title")
    ]))) {
        try parser.parse(
            invalid,
            originalInput: "1. Open the box.",
            repairOutputs: [validJSON]
        )
    }
}

@Test
func repairPromptIncludesValidationIssues() {
    let report = StepValidationReport(issues: [
        StepValidationIssue(severity: .error, code: .emptyTitle, message: "Step title must not be empty.", path: "document.sections[0].steps[0].title")
    ])

    let prompt = StepPromptSet.repairPrompt(
        originalInput: "1. Wait 5 min",
        previousOutput: #"{"sections":[{"steps":[{"title":""}]}]}"#,
        validationReport: report
    )

    #expect(prompt.contains("Repair the JSON output"))
    #expect(prompt.contains("emptyTitle"))
    #expect(prompt.contains("Return strict JSON only"))
}

@Test
func mockExtractorReturnsExpectedResult() async throws {
    let document = StepDocument(sections: [StepSection(steps: [Step(id: "one", title: "Review the text")])])
    let expected = StepExtractionResult(document: document, validationReport: StepValidator().validate(document))
    let extractor = MockStepExtractor(result: expected)

    let result = try await extractor.extractSteps(from: "Review the text.")

    #expect(result == expected)
}

private let validJSON = """
{
  "id": "doc",
  "title": "Checklist",
  "sections": [
    {
      "id": "main",
      "title": "Main",
      "steps": [
        {
          "id": "open",
          "title": "Open the box",
          "detail": "Place contents on a clean surface.",
          "kind": "action",
          "state": "done",
          "warnings": [],
          "metadata": {}
        },
        {
          "id": "wait",
          "title": "Wait 5 min",
          "kind": "wait",
          "duration": {"kind": "minutes", "value": 5},
          "state": "todo",
          "warnings": [],
          "metadata": {}
        }
      ]
    }
  ],
  "metadata": {}
}
"""
