// Issues #199, #201, #203, #206, #208, #210 — ASC build and metadata models

import Foundation

// MARK: - Issue #199 — ASCVersion

public struct ASCVersion: Identifiable, Sendable, Equatable {
    public let id: String
    public let versionString: String
    public let platform: ASCPlatform
    public let state: ASCVersionState

    nonisolated public init(id: String, versionString: String, platform: ASCPlatform, state: ASCVersionState) {
        self.id = id
        self.versionString = versionString
        self.platform = platform
        self.state = state
    }
}

public enum ASCVersionState: String, Sendable, Equatable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case pendingDeveloperRelease = "PENDING_DEVELOPER_RELEASE"
    case readyForSale = "READY_FOR_SALE"
    case rejected = "REJECTED"
    case developerRemovedFromSale = "DEVELOPER_REMOVED_FROM_SALE"
    case unknown

    public var displayName: String {
        switch self {
        case .prepareForSubmission: "Prepare for Submission"
        case .waitingForReview: "Waiting for Review"
        case .inReview: "In Review"
        case .pendingDeveloperRelease: "Pending Developer Release"
        case .readyForSale: "Ready for Sale"
        case .rejected: "Rejected"
        case .developerRemovedFromSale: "Removed from Sale"
        case .unknown: "Unknown"
        }
    }
}

// MARK: - Issue #201 — ASCBuild

public struct ASCBuild: Identifiable, Sendable, Equatable {
    public let id: String
    public let version: String
    public let buildNumber: String
    public let uploadedDate: Date?
    public let processingState: ASCBuildProcessingState
    public let iconURL: String?

    nonisolated public init(
        id: String, version: String, buildNumber: String,
        uploadedDate: Date?, processingState: ASCBuildProcessingState,
        iconURL: String? = nil
    ) {
        self.id = id
        self.version = version
        self.buildNumber = buildNumber
        self.uploadedDate = uploadedDate
        self.processingState = processingState
        self.iconURL = iconURL
    }
}

public enum ASCBuildProcessingState: String, Sendable, Equatable {
    case processing = "PROCESSING"
    case failed = "FAILED"
    case invalid = "INVALID"
    case valid = "VALID"
    case unknown

    public var displayName: String {
        switch self {
        case .processing: "Processing"
        case .failed: "Failed"
        case .invalid: "Invalid"
        case .valid: "Valid"
        case .unknown: "Unknown"
        }
    }
}

// MARK: - Issue #203 — ASCTestFlightBuild

public struct ASCTestFlightBuild: Identifiable, Sendable, Equatable {
    public let id: String
    public let buildNumber: String
    public let version: String
    public let betaState: ASCBetaState
    public let expirationDate: Date?
    public let testerGroups: [String]

    nonisolated public init(
        id: String, buildNumber: String, version: String,
        betaState: ASCBetaState, expirationDate: Date?,
        testerGroups: [String] = []
    ) {
        self.id = id
        self.buildNumber = buildNumber
        self.version = version
        self.betaState = betaState
        self.expirationDate = expirationDate
        self.testerGroups = testerGroups
    }
}

public enum ASCBetaState: String, Sendable, Equatable {
    case readyForBetaTesting = "READY_FOR_BETA_TESTING"
    case inBetaTesting = "IN_BETA_TESTING"
    case expired = "EXPIRED"
    case inExportComplianceReview = "IN_EXPORT_COMPLIANCE_REVIEW"
    case waitingForBetaReview = "WAITING_FOR_BETA_REVIEW"
    case inBetaReview = "IN_BETA_REVIEW"
    case betaRejected = "BETA_REJECTED"
    case betaApproved = "BETA_APPROVED"
    case unknown

    public var displayName: String {
        switch self {
        case .readyForBetaTesting: "Ready for Testing"
        case .inBetaTesting: "In Testing"
        case .expired: "Expired"
        case .inExportComplianceReview: "Export Compliance Review"
        case .waitingForBetaReview: "Waiting for Review"
        case .inBetaReview: "In Review"
        case .betaRejected: "Rejected"
        case .betaApproved: "Approved"
        case .unknown: "Unknown"
        }
    }
}

// MARK: - Issue #206 — ASCReleaseNotes

public struct ASCReleaseNotes: Identifiable, Sendable, Equatable {
    public let id: String
    public let locale: String
    public let whatsNew: String?

    nonisolated public init(id: String, locale: String, whatsNew: String?) {
        self.id = id
        self.locale = locale
        self.whatsNew = whatsNew
    }
}

// MARK: - Issue #208 — ASCMetadataStatus

public struct ASCMetadataStatus: Sendable, Equatable {
    public let fields: [ASCMetadataField]
    public let completeness: Double

    nonisolated public init(fields: [ASCMetadataField]) {
        self.fields = fields
        let total = fields.count
        let complete = fields.filter(\.isComplete).count
        self.completeness = total > 0 ? Double(complete) / Double(total) : 0
    }
}

public struct ASCMetadataField: Identifiable, Sendable, Equatable {
    public let id: String
    public let label: String
    public let isComplete: Bool
    public let value: String?

    nonisolated public init(id: String, label: String, isComplete: Bool, value: String? = nil) {
        self.id = id
        self.label = label
        self.isComplete = isComplete
        self.value = value
    }
}

// MARK: - Required Metadata Fields

public enum ASCRequiredField: Sendable {
    nonisolated public static let all: [String] = [
        "name", "subtitle", "description", "keywords",
        "supportUrl", "marketingUrl", "privacyPolicyUrl"
    ]

    nonisolated public static let labels: [String: String] = [
        "name": "App Name",
        "subtitle": "Subtitle",
        "description": "Description",
        "keywords": "Keywords",
        "supportUrl": "Support URL",
        "marketingUrl": "Marketing URL",
        "privacyPolicyUrl": "Privacy Policy URL",
    ]
}

// MARK: - Issue #210 — ASCLocalizationStatus

public struct ASCLocalizationStatus: Sendable, Equatable {
    public let locales: [ASCLocaleCompleteness]
    public let overallCompleteness: Double

    nonisolated public init(locales: [ASCLocaleCompleteness]) {
        self.locales = locales
        let total = locales.count
        let sum = locales.reduce(0.0) { $0 + $1.completeness }
        self.overallCompleteness = total > 0 ? sum / Double(total) : 0
    }
}

public struct ASCLocaleCompleteness: Identifiable, Sendable, Equatable {
    public var id: String { locale }
    public let locale: String
    public let completeness: Double
    public let missingFields: [String]

    nonisolated public init(locale: String, completeness: Double, missingFields: [String] = []) {
        self.locale = locale
        self.completeness = completeness
        self.missingFields = missingFields
    }
}
