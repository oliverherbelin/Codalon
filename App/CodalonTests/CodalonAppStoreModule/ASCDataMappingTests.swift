// Issue #225 — ASC API response to display model mapping tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Data Mapping Tests

@Suite("ASCDataMapping")
@MainActor
struct ASCDataMappingTests {

    // MARK: - Version State Mapping

    @Test("version state display names")
    func versionStateDisplayNames() {
        #expect(ASCVersionState.prepareForSubmission.displayName == "Prepare for Submission")
        #expect(ASCVersionState.waitingForReview.displayName == "Waiting for Review")
        #expect(ASCVersionState.inReview.displayName == "In Review")
        #expect(ASCVersionState.readyForSale.displayName == "Ready for Sale")
        #expect(ASCVersionState.rejected.displayName == "Rejected")
        #expect(ASCVersionState.unknown.displayName == "Unknown")
    }

    @Test("version state raw value mapping")
    func versionStateRawValues() {
        #expect(ASCVersionState(rawValue: "PREPARE_FOR_SUBMISSION") == .prepareForSubmission)
        #expect(ASCVersionState(rawValue: "READY_FOR_SALE") == .readyForSale)
        #expect(ASCVersionState(rawValue: "NONSENSE") == nil)
    }

    // MARK: - Build Processing State Mapping

    @Test("build processing state display names")
    func buildProcessingStateDisplayNames() {
        #expect(ASCBuildProcessingState.processing.displayName == "Processing")
        #expect(ASCBuildProcessingState.valid.displayName == "Valid")
        #expect(ASCBuildProcessingState.failed.displayName == "Failed")
        #expect(ASCBuildProcessingState.invalid.displayName == "Invalid")
    }

    @Test("build processing state raw values")
    func buildProcessingStateRawValues() {
        #expect(ASCBuildProcessingState(rawValue: "VALID") == .valid)
        #expect(ASCBuildProcessingState(rawValue: "PROCESSING") == .processing)
        #expect(ASCBuildProcessingState(rawValue: "BOGUS") == nil)
    }

    // MARK: - Beta State Mapping

    @Test("beta state display names")
    func betaStateDisplayNames() {
        #expect(ASCBetaState.readyForBetaTesting.displayName == "Ready for Testing")
        #expect(ASCBetaState.inBetaTesting.displayName == "In Testing")
        #expect(ASCBetaState.expired.displayName == "Expired")
        #expect(ASCBetaState.betaRejected.displayName == "Rejected")
    }

    // MARK: - Metadata Status Mapping

    @Test("metadata completeness calculates correctly — all complete")
    func metadataCompletenessAllComplete() {
        let fields = [
            ASCMetadataField(id: "name", label: "Name", isComplete: true),
            ASCMetadataField(id: "desc", label: "Description", isComplete: true),
        ]
        let status = ASCMetadataStatus(fields: fields)
        #expect(status.completeness == 1.0)
    }

    @Test("metadata completeness calculates correctly — partial")
    func metadataCompletenessPartial() {
        let fields = [
            ASCMetadataField(id: "name", label: "Name", isComplete: true),
            ASCMetadataField(id: "desc", label: "Description", isComplete: false),
            ASCMetadataField(id: "keywords", label: "Keywords", isComplete: false),
            ASCMetadataField(id: "url", label: "URL", isComplete: true),
        ]
        let status = ASCMetadataStatus(fields: fields)
        #expect(status.completeness == 0.5)
    }

    @Test("metadata completeness with empty fields is 0")
    func metadataCompletenessEmpty() {
        let status = ASCMetadataStatus(fields: [])
        #expect(status.completeness == 0)
    }

    // MARK: - Localization Status Mapping

    @Test("localization overall completeness calculates correctly")
    func localizationOverallCompleteness() {
        let locales = [
            ASCLocaleCompleteness(locale: "en-US", completeness: 1.0),
            ASCLocaleCompleteness(locale: "de-DE", completeness: 0.6),
            ASCLocaleCompleteness(locale: "fr-FR", completeness: 0.4),
        ]
        let status = ASCLocalizationStatus(locales: locales)
        // (1.0 + 0.6 + 0.4) / 3 = 0.666...
        #expect(status.overallCompleteness > 0.66 && status.overallCompleteness < 0.67)
    }

    @Test("localization overall completeness with no locales is 0")
    func localizationCompletenessEmpty() {
        let status = ASCLocalizationStatus(locales: [])
        #expect(status.overallCompleteness == 0)
    }

    @Test("locale completeness tracks missing fields")
    func localeMissingFields() {
        let locale = ASCLocaleCompleteness(
            locale: "de-DE",
            completeness: 0.6,
            missingFields: ["keywords", "whatsNew"]
        )
        #expect(locale.missingFields.count == 2)
        #expect(locale.missingFields.contains("keywords"))
    }

    // MARK: - Platform Mapping

    @Test("platform display names")
    func platformDisplayNames() {
        #expect(ASCPlatform.iOS.displayName == "iOS")
        #expect(ASCPlatform.macOS.displayName == "macOS")
        #expect(ASCPlatform.tvOS.displayName == "tvOS")
        #expect(ASCPlatform.visionOS.displayName == "visionOS")
    }

    @Test("platform raw value mapping")
    func platformRawValues() {
        #expect(ASCPlatform(rawValue: "IOS") == .iOS)
        #expect(ASCPlatform(rawValue: "MAC_OS") == .macOS)
        #expect(ASCPlatform(rawValue: "UNKNOWN_PLATFORM") == nil)
    }

    // MARK: - ASCVersion Equality

    @Test("ASCVersion equality")
    func versionEquality() {
        let v1 = ASCVersion(id: "1", versionString: "1.0", platform: .macOS, state: .readyForSale)
        let v2 = ASCVersion(id: "1", versionString: "1.0", platform: .macOS, state: .readyForSale)
        #expect(v1 == v2)
    }

    // MARK: - ASCBuild Equality

    @Test("ASCBuild equality")
    func buildEquality() {
        let b1 = ASCBuild(id: "1", version: "1.0", buildNumber: "42", uploadedDate: nil, processingState: .valid)
        let b2 = ASCBuild(id: "1", version: "1.0", buildNumber: "42", uploadedDate: nil, processingState: .valid)
        #expect(b1 == b2)
    }
}
