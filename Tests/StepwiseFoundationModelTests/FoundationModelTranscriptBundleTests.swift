import Foundation
import Testing
import StepwiseCore
import StepwiseFoundationModel

private enum FoundationModelTranscriptBundle {
    static var transcriptsDirectoryURL: URL {
        guard let resourceURL = Bundle.module.resourceURL else {
            preconditionFailure("StepwiseFoundationModelTests bundle is missing resources.")
        }

        guard FileManager.default.fileExists(atPath: resourceURL.path) else {
            preconditionFailure("StepwiseFoundationModelTests bundle resource directory is missing at \(resourceURL.path)")
        }

        return resourceURL
    }
}

@Test
func bundledFoundationModelTranscriptsCanReplayDownstreamClients() async throws {
    let transcriptsDirectoryURL = FoundationModelTranscriptBundle.transcriptsDirectoryURL
    let transcriptURLs = try FileManager.default.contentsOfDirectory(
        at: transcriptsDirectoryURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    ).filter { $0.pathExtension.lowercased() == "json" }

    #expect(transcriptURLs.count == 4)

    for fixture in FoundationModelSanityFixtures.all {
        let extractor = try FoundationModelTranscriptExtractor(
            transcriptDirectoryURL: transcriptsDirectoryURL,
            configuration: fixture.configuration
        )

        let result = try await extractor.extractSteps(from: fixture.input)
        #expect(fixture.rubricFailures(for: result).isEmpty)
    }
}
