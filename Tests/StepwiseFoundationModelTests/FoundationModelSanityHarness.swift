import Foundation
import Testing
import StepwiseFoundationModel

#if canImport(FoundationModels)
import FoundationModels
#endif

struct FoundationModelSanityFixture: Sendable {
    struct DurationExpectation: Sendable {
        let cues: [String]
        let exactSeconds: Int
    }

    let id: String
    let input: String
    let configuration: StepExtractionConfiguration
    let referenceOutput: String
    let minimumStepCount: Int
    let documentTitleTokens: [String]
    let requiredCueGroups: [[String]]
    let requiredDurations: [DurationExpectation]

    func rubricFailures(for result: StepExtractionResult) -> [String] {
        var failures: [String] = []
        let document = result.document
        let searchableSteps = document.steps.map {
            "\($0.title) \($0.detail ?? "")".lowercased()
        }

        if !result.validationReport.isValid {
            failures.append("validation report contains issues")
        }

        if document.steps.count < minimumStepCount {
            failures.append(
                "expected at least \(minimumStepCount) steps, got \(document.steps.count)"
            )
        }

        let loweredTitle = (document.title ?? "").lowercased()
        for token in documentTitleTokens where !loweredTitle.contains(token.lowercased()) {
            failures.append("document title is missing token '\(token)'")
        }

        for cueGroup in requiredCueGroups {
            let matched = cueGroup.contains { cue in
                searchableSteps.contains { $0.contains(cue.lowercased()) }
            }

            if !matched {
                failures.append(
                    "missing step content matching one of: \(cueGroup.joined(separator: ", "))"
                )
            }
        }

        for duration in requiredDurations {
            guard let matchingStep = document.steps.first(where: { step in
                let searchable = "\(step.title) \(step.detail ?? "")".lowercased()
                return duration.cues.contains { searchable.contains($0.lowercased()) }
            }) else {
                failures.append(
                    "missing duration cue matching one of: \(duration.cues.joined(separator: ", "))"
                )
                continue
            }

            let exactSeconds = matchingStep.duration?.exactSeconds ?? matchingStep.timer?.duration.exactSeconds
            if exactSeconds != duration.exactSeconds {
                let actual = exactSeconds.map(String.init(describing:)) ?? "nil"
                failures.append(
                    "expected \(duration.exactSeconds) seconds for cues \(duration.cues.joined(separator: ", ")), got \(actual)"
                )
            }
        }

        return failures
    }
}

enum FoundationModelSanityFixtures {
    static let all: [FoundationModelSanityFixture] = [
        FoundationModelSanityFixture(
            id: "equipment_setup",
            input: """
            Equipment Setup
            1. Open the kit.
            2. Connect the marked cable.
            3. Wait 30 sec.
            4. Confirm the status light is solid.
            """,
            configuration: StepExtractionConfiguration(domain: .checklist, title: "Equipment Setup"),
            referenceOutput: """
            {
                            "id": "equipment-setup",
              "title": "Equipment Setup",
              "sections": [
                {
                                    "id": "main",
                  "title": "Main",
                  "steps": [
                    {
                                            "id": "open",
                      "title": "Open the kit",
                      "kind": "action",
                                            "state": "todo",
                      "warnings": [],
                      "metadata": {}
                    },
                    {
                                            "id": "connect",
                      "title": "Connect the cable",
                      "detail": "Use the marked cable.",
                      "kind": "action",
                                            "state": "todo",
                      "warnings": [],
                      "metadata": {}
                    },
                    {
                                            "id": "wait",
                      "title": "Wait 30 sec",
                      "kind": "wait",
                      "duration": {"kind": "seconds", "value": 30},
                                            "state": "todo",
                      "warnings": [],
                      "metadata": {}
                    },
                    {
                                            "id": "confirm",
                      "title": "Confirm the status light",
                      "detail": "Check that the light is solid.",
                      "kind": "check",
                                            "state": "todo",
                      "warnings": [],
                      "metadata": {}
                    }
                  ]
                }
              ],
              "metadata": {}
            }
            """,
            minimumStepCount: 4,
            documentTitleTokens: ["equipment", "setup"],
            requiredCueGroups: [
                ["open the kit", "open"],
                ["cable", "connect"],
                ["wait", "30 sec"],
                ["status light", "confirm"]
            ],
            requiredDurations: [
                .init(cues: ["wait", "30 sec"], exactSeconds: 30)
            ]
        ),
        FoundationModelSanityFixture(
            id: "spaghetti_carbonara",
            input: """
            Spaghetti Carbonara
            1. Boil salted water.
            2. Cook 120 g spaghetti for 10 min.
            3. Whisk 2 egg yolks with 35 g pecorino and black pepper.
            4. Toss off heat with reserved pasta water.
            """,
            configuration: StepExtractionConfiguration(domain: .recipe, title: "Spaghetti Carbonara"),
            referenceOutput: """
            {
                            "id": "carbonara",
              "title": "Spaghetti Carbonara",
              "sections": [
                {
                                    "id": "cook",
                  "title": "Cook",
                  "steps": [
                    {
                                            "id": "boil",
                      "title": "Boil salted water",
                      "kind": "action",
                                            "state": "todo",
                      "warnings": [],
                      "metadata": {}
                    },
                    {
                                            "id": "spaghetti",
                      "title": "Cook the spaghetti",
                      "detail": "Cook 120 g spaghetti for 10 min.",
                      "kind": "timer",
                      "duration": {"kind": "minutes", "value": 10},
                      "timer": {
                                                "id": "spaghetti-timer",
                        "duration": {"kind": "minutes", "value": 10},
                        "automaticallyStarts": false
                      },
                                            "state": "todo",
                      "warnings": [],
                      "metadata": {}
                    },
                    {
                                            "id": "whisk",
                      "title": "Whisk egg yolks with pecorino",
                      "detail": "Add black pepper.",
                      "kind": "action",
                                            "state": "todo",
                      "warnings": [],
                      "metadata": {}
                    },
                    {
                                            "id": "toss",
                      "title": "Toss with pasta water off heat",
                      "kind": "action",
                                            "state": "todo",
                      "warnings": [],
                      "metadata": {}
                    }
                  ]
                }
              ],
              "metadata": {}
            }
            """,
            minimumStepCount: 4,
            documentTitleTokens: ["spaghetti", "carbonara"],
            requiredCueGroups: [
                ["boil", "water"],
                ["spaghetti", "pasta"],
                ["egg", "yolk"],
                ["pecorino", "cheese"],
                ["pasta water", "reserved water", "water"]
            ],
            requiredDurations: [
                .init(cues: ["spaghetti", "cook"], exactSeconds: 600)
            ]
        )
    ]
}

struct FoundationModelFixtureMeasurement: Sendable {
    let fixtureID: String
    let duration: Duration
    let stepCount: Int
    let rawOutputLength: Int
}

enum FoundationModelLiveTestHarness {
    static let environmentVariable = "STEPWISE_RUN_FOUNDATION_MODEL_TESTS"

    static var isOptedIn: Bool {
        ProcessInfo.processInfo.environment[environmentVariable] == "1"
    }

    static func shouldRun(testName: String) -> Bool {
        guard isOptedIn else {
            logSkip(
                testName: testName,
                reason: "set \(environmentVariable)=1 to enable live Foundation Models tests."
            )
            return false
        }

        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, *) else {
            logSkip(
                testName: testName,
                reason: "Foundation Models APIs require iOS 26 or macOS 26."
            )
            return false
        }

        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable(.appleIntelligenceNotEnabled):
            logSkip(testName: testName, reason: "Apple Intelligence is not enabled.")
            return false
        case .unavailable(.deviceNotEligible):
            logSkip(testName: testName, reason: "device is not eligible for Foundation Models.")
            return false
        case .unavailable(.modelNotReady):
            logSkip(testName: testName, reason: "Foundation Models assets are not ready.")
            return false
        @unknown default:
            logSkip(testName: testName, reason: "Foundation Models reported an unknown availability state.")
            return false
        }
        #else
        logSkip(testName: testName, reason: "FoundationModels framework is unavailable in this SDK.")
        return false
        #endif
    }

    private static func logSkip(testName: String, reason: String) {
        print("[StepwiseFoundationModel] Skipping \(testName): \(reason) \(environmentSnapshot())")
    }

    private static func environmentSnapshot() -> String {
        let runtimeVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let sdkVersion = shellOutput(
            "/usr/bin/xcrun",
            arguments: ["--sdk", "macosx", "--show-sdk-version"]
        ) ?? "unknown"
        let sdkPath = shellOutput(
            "/usr/bin/xcrun",
            arguments: ["--sdk", "macosx", "--show-sdk-path"]
        ) ?? "unknown"
        let xcodeVersion = shellOutput(
            "/usr/bin/xcodebuild",
            arguments: ["-version"]
        )?.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? "unknown"

        return "[runtime=\(runtimeVersion) sdk_version=\(sdkVersion) sdk_path=\(sdkPath) xcode=\(xcodeVersion)]"
    }

    private static func shellOutput(_ executablePath: String, arguments: [String]) -> String? {
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let standardOutput = Pipe()
        process.standardOutput = standardOutput
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = standardOutput.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func log(measurements: [FoundationModelFixtureMeasurement]) {
        guard !measurements.isEmpty else {
            print("[StepwiseFoundationModel] No live measurements were collected.")
            return
        }

        let totalMilliseconds = measurements.reduce(0.0) { partial, measurement in
            partial + milliseconds(for: measurement.duration)
        }
        let averageMilliseconds = totalMilliseconds / Double(measurements.count)
        let slowest = measurements.max { lhs, rhs in
            milliseconds(for: lhs.duration) < milliseconds(for: rhs.duration)
        }

        for measurement in measurements {
            print(
                "[StepwiseFoundationModel] fixture=\(measurement.fixtureID) duration_ms=\(format(milliseconds(for: measurement.duration))) steps=\(measurement.stepCount) raw_chars=\(measurement.rawOutputLength)"
            )
        }

        if let slowest {
            print(
                "[StepwiseFoundationModel] summary fixtures=\(measurements.count) total_ms=\(format(totalMilliseconds)) avg_ms=\(format(averageMilliseconds)) slowest=\(slowest.fixtureID) slowest_ms=\(format(milliseconds(for: slowest.duration)))"
            )
        }
    }

    private static func milliseconds(for duration: Duration) -> Double {
        let components = duration.components
        return (Double(components.seconds) * 1_000) + (Double(components.attoseconds) / 1_000_000_000_000_000)
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}