// Issue #185 — App Store Connect API client with JWT authentication

import Foundation
import CryptoKit
import HelaiaLogger

// MARK: - Protocol

public protocol ASCAPIClientProtocol: Sendable {
    func fetchApps(credential: ASCCredential) async throws -> [ASCApp]
    func validateCredentials(_ credential: ASCCredential) async throws -> Bool
    func fetchVersions(appID: String, credential: ASCCredential) async throws -> [ASCVersion]
    func fetchBuilds(appID: String, credential: ASCCredential) async throws -> [ASCBuild]
    func fetchTestFlightBuilds(appID: String, credential: ASCCredential) async throws -> [ASCTestFlightBuild]
    func fetchReleaseNotes(versionID: String, credential: ASCCredential) async throws -> [ASCReleaseNotes]
    func updateReleaseNotes(localizationID: String, whatsNew: String, credential: ASCCredential) async throws
    func fetchAppInfo(appID: String, credential: ASCCredential) async throws -> [ASCMetadataField]
    func fetchLocalizations(versionID: String, credential: ASCCredential) async throws -> [ASCLocaleCompleteness]
}

// MARK: - JWT Types

private struct JWTHeader: Sendable {
    let alg = "ES256"
    let typ = "JWT"
    let kid: String

    nonisolated func encoded() throws -> Data {
        let dict: [String: String] = ["alg": alg, "typ": typ, "kid": kid]
        return try JSONSerialization.data(withJSONObject: dict)
    }
}

private struct JWTPayload: Sendable {
    let iss: String
    let iat: Int
    let exp: Int
    let aud: String

    nonisolated func encoded() throws -> Data {
        let dict: [String: Any] = ["iss": iss, "iat": iat, "exp": exp, "aud": aud]
        return try JSONSerialization.data(withJSONObject: dict)
    }
}

// MARK: - ASC API Response Types

private struct ASCAppsResponse: Sendable {
    let data: [ASCAppItem]
}

private struct ASCAppItem: Sendable {
    let id: String
    let attributes: ASCAppAttributes
}

private struct ASCAppAttributes: Sendable {
    let name: String
    let bundleId: String
    let platform: String
}

extension ASCAppsResponse {
    nonisolated static func decode(from data: Data) throws -> ASCAppsResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]] else {
            throw ASCServiceError.decodingFailed
        }

        let appItems = items.compactMap { item -> ASCAppItem? in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let name = attrs["name"] as? String,
                  let bundleId = attrs["bundleId"] as? String,
                  let platform = attrs["platform"] as? String else { return nil }
            return ASCAppItem(
                id: id,
                attributes: ASCAppAttributes(name: name, bundleId: bundleId, platform: platform)
            )
        }
        return ASCAppsResponse(data: appItems)
    }
}

// MARK: - Base64URL

private nonisolated func base64URLEncode(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

// MARK: - Implementation

public actor ASCAPIClient: ASCAPIClientProtocol {

    private let logger: any HelaiaLoggerProtocol
    nonisolated private static let baseURL = "https://api.appstoreconnect.apple.com/v1"

    public init(logger: any HelaiaLoggerProtocol) {
        self.logger = logger
    }

    // MARK: - Issue #185 — Fetch Apps

    public func fetchApps(credential: ASCCredential) async throws -> [ASCApp] {
        logger.info("Fetching ASC apps list", category: "asc")

        let token = try generateJWT(credential: credential)
        let url = URL(string: "\(Self.baseURL)/apps?fields[apps]=name,bundleId,platform&limit=50")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ASCServiceError.requestFailed(statusCode: -1)
        }

        guard (200..<300).contains(http.statusCode) else {
            logger.error("ASC fetchApps failed with status \(http.statusCode)", category: "asc")
            if http.statusCode == 401 || http.statusCode == 403 {
                throw ASCServiceError.credentialsExpired
            }
            throw ASCServiceError.requestFailed(statusCode: http.statusCode)
        }

        let decoded = try ASCAppsResponse.decode(from: data)
        let apps = decoded.data.map { item in
            ASCApp(
                id: item.id,
                name: item.attributes.name,
                bundleID: item.attributes.bundleId,
                platform: ASCPlatform(rawValue: item.attributes.platform) ?? .macOS
            )
        }

        logger.info("Fetched \(apps.count) ASC apps", category: "asc")
        return apps
    }

    public func validateCredentials(_ credential: ASCCredential) async throws -> Bool {
        logger.info("Validating ASC credentials", category: "asc")

        let token = try generateJWT(credential: credential)
        let url = URL(string: "\(Self.baseURL)/apps?limit=1")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            return false
        }

        let valid = (200..<300).contains(http.statusCode)
        if valid {
            logger.success("ASC credentials valid", category: "asc")
        } else {
            logger.warning("ASC credentials invalid (status \(http.statusCode))", category: "asc")
        }
        return valid
    }

    // MARK: - Issue #199 — Fetch Versions

    public func fetchVersions(appID: String, credential: ASCCredential) async throws -> [ASCVersion] {
        logger.info("Fetching ASC versions for app \(appID)", category: "asc")
        let data = try await authenticatedGet(
            path: "/apps/\(appID)/appStoreVersions?fields[appStoreVersions]=versionString,platform,appStoreState",
            credential: credential
        )
        return try decodeVersions(from: data)
    }

    // MARK: - Issue #201 — Fetch Builds

    public func fetchBuilds(appID: String, credential: ASCCredential) async throws -> [ASCBuild] {
        logger.info("Fetching ASC builds for app \(appID)", category: "asc")
        let data = try await authenticatedGet(
            path: "/builds?filter[app]=\(appID)&fields[builds]=version,uploadedDate,processingState,iconAssetToken&sort=-uploadedDate&limit=20",
            credential: credential
        )
        return try decodeBuilds(from: data)
    }

    // MARK: - Issue #203 — Fetch TestFlight Builds

    public func fetchTestFlightBuilds(appID: String, credential: ASCCredential) async throws -> [ASCTestFlightBuild] {
        logger.info("Fetching ASC TestFlight builds for app \(appID)", category: "asc")
        let data = try await authenticatedGet(
            path: "/builds?filter[app]=\(appID)&filter[betaAppReviewSubmission.betaReviewState]=APPROVED&fields[builds]=version,uploadedDate,expirationDate,buildBetaDetail&limit=20",
            credential: credential
        )
        return try decodeTestFlightBuilds(from: data)
    }

    // MARK: - Issue #206 — Fetch Release Notes

    public func fetchReleaseNotes(versionID: String, credential: ASCCredential) async throws -> [ASCReleaseNotes] {
        logger.info("Fetching ASC release notes for version \(versionID)", category: "asc")
        let data = try await authenticatedGet(
            path: "/appStoreVersions/\(versionID)/appStoreVersionLocalizations?fields[appStoreVersionLocalizations]=locale,whatsNew",
            credential: credential
        )
        return try decodeReleaseNotes(from: data)
    }

    // MARK: - Issue #217 — Update Release Notes

    public func updateReleaseNotes(localizationID: String, whatsNew: String, credential: ASCCredential) async throws {
        logger.info("Updating ASC release notes for localization \(localizationID)", category: "asc")

        let token = try generateJWT(credential: credential)
        let url = URL(string: "\(Self.baseURL)/appStoreVersionLocalizations/\(localizationID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "data": [
                "type": "appStoreVersionLocalizations",
                "id": localizationID,
                "attributes": ["whatsNew": whatsNew]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("ASC updateReleaseNotes failed with status \(statusCode)", category: "asc")
            throw ASCServiceError.requestFailed(statusCode: statusCode)
        }
        logger.success("Release notes updated for \(localizationID)", category: "asc")
    }

    // MARK: - Issue #208 — Fetch App Info (Metadata)

    public func fetchAppInfo(appID: String, credential: ASCCredential) async throws -> [ASCMetadataField] {
        logger.info("Fetching ASC app info for \(appID)", category: "asc")
        let data = try await authenticatedGet(
            path: "/apps/\(appID)/appInfos?include=appInfoLocalizations&fields[appInfoLocalizations]=name,subtitle&fields[appInfos]=appStoreState",
            credential: credential
        )
        return try decodeMetadataFields(from: data)
    }

    // MARK: - Issue #210 — Fetch Localizations

    public func fetchLocalizations(versionID: String, credential: ASCCredential) async throws -> [ASCLocaleCompleteness] {
        logger.info("Fetching ASC localizations for version \(versionID)", category: "asc")
        let data = try await authenticatedGet(
            path: "/appStoreVersions/\(versionID)/appStoreVersionLocalizations?fields[appStoreVersionLocalizations]=locale,description,keywords,supportUrl,marketingUrl,whatsNew",
            credential: credential
        )
        return try decodeLocalizations(from: data)
    }

    // MARK: - Authenticated GET helper

    private func authenticatedGet(path: String, credential: ASCCredential) async throws -> Data {
        let token = try generateJWT(credential: credential)
        let url = URL(string: "\(Self.baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ASCServiceError.requestFailed(statusCode: -1)
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw ASCServiceError.credentialsExpired
            }
            throw ASCServiceError.requestFailed(statusCode: http.statusCode)
        }
        return data
    }

    // MARK: - Response Decoders

    private nonisolated func decodeVersions(from data: Data) throws -> [ASCVersion] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]] else {
            throw ASCServiceError.decodingFailed
        }
        return items.compactMap { item -> ASCVersion? in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let versionString = attrs["versionString"] as? String,
                  let platformRaw = attrs["platform"] as? String,
                  let stateRaw = attrs["appStoreState"] as? String else { return nil }
            return ASCVersion(
                id: id,
                versionString: versionString,
                platform: ASCPlatform(rawValue: platformRaw) ?? .macOS,
                state: ASCVersionState(rawValue: stateRaw) ?? .unknown
            )
        }
    }

    private nonisolated func decodeBuilds(from data: Data) throws -> [ASCBuild] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]] else {
            throw ASCServiceError.decodingFailed
        }
        let formatter = ISO8601DateFormatter()
        return items.compactMap { item -> ASCBuild? in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let version = attrs["version"] as? String else { return nil }
            let uploadedDate = (attrs["uploadedDate"] as? String).flatMap { formatter.date(from: $0) }
            let stateRaw = attrs["processingState"] as? String ?? ""
            return ASCBuild(
                id: id,
                version: version,
                buildNumber: version,
                uploadedDate: uploadedDate,
                processingState: ASCBuildProcessingState(rawValue: stateRaw) ?? .unknown
            )
        }
    }

    private nonisolated func decodeTestFlightBuilds(from data: Data) throws -> [ASCTestFlightBuild] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]] else {
            throw ASCServiceError.decodingFailed
        }
        let formatter = ISO8601DateFormatter()
        return items.compactMap { item -> ASCTestFlightBuild? in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let version = attrs["version"] as? String else { return nil }
            let expirationDate = (attrs["expirationDate"] as? String).flatMap { formatter.date(from: $0) }
            let betaDetail = attrs["buildBetaDetail"] as? [String: Any]
            let betaStateRaw = (betaDetail?["attributes"] as? [String: Any])?["externalBuildState"] as? String ?? ""
            return ASCTestFlightBuild(
                id: id,
                buildNumber: version,
                version: version,
                betaState: ASCBetaState(rawValue: betaStateRaw) ?? .unknown,
                expirationDate: expirationDate
            )
        }
    }

    private nonisolated func decodeReleaseNotes(from data: Data) throws -> [ASCReleaseNotes] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]] else {
            throw ASCServiceError.decodingFailed
        }
        return items.compactMap { item -> ASCReleaseNotes? in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let locale = attrs["locale"] as? String else { return nil }
            let whatsNew = attrs["whatsNew"] as? String
            return ASCReleaseNotes(id: id, locale: locale, whatsNew: whatsNew)
        }
    }

    private nonisolated func decodeMetadataFields(from data: Data) throws -> [ASCMetadataField] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let included = json["included"] as? [[String: Any]] else {
            throw ASCServiceError.decodingFailed
        }
        // Check first localization for required fields
        guard let first = included.first,
              let attrs = first["attributes"] as? [String: Any] else {
            return ASCRequiredField.all.map {
                ASCMetadataField(id: $0, label: ASCRequiredField.labels[$0] ?? $0, isComplete: false)
            }
        }
        return ASCRequiredField.all.map { field in
            let value = attrs[field] as? String
            let isComplete = value != nil && !value!.isEmpty
            return ASCMetadataField(
                id: field,
                label: ASCRequiredField.labels[field] ?? field,
                isComplete: isComplete,
                value: value
            )
        }
    }

    private nonisolated func decodeLocalizations(from data: Data) throws -> [ASCLocaleCompleteness] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]] else {
            throw ASCServiceError.decodingFailed
        }
        let requiredFields = ["description", "keywords", "supportUrl", "marketingUrl", "whatsNew"]
        return items.compactMap { item -> ASCLocaleCompleteness? in
            guard let attrs = item["attributes"] as? [String: Any],
                  let locale = attrs["locale"] as? String else { return nil }
            var missing: [String] = []
            for field in requiredFields {
                let value = attrs[field] as? String
                if value == nil || value!.isEmpty {
                    missing.append(field)
                }
            }
            let completeness = Double(requiredFields.count - missing.count) / Double(requiredFields.count)
            return ASCLocaleCompleteness(locale: locale, completeness: completeness, missingFields: missing)
        }
    }

    // MARK: - JWT Generation

    private func generateJWT(credential: ASCCredential) throws -> String {
        let header = JWTHeader(kid: credential.keyID)
        let now = Date()
        let payload = JWTPayload(
            iss: credential.issuerID,
            iat: Int(now.timeIntervalSince1970),
            exp: Int(now.addingTimeInterval(20 * 60).timeIntervalSince1970),
            aud: "appstoreconnect-v1"
        )

        let headerData = try header.encoded()
        let payloadData = try payload.encoded()

        let headerBase64 = base64URLEncode(headerData)
        let payloadBase64 = base64URLEncode(payloadData)

        let signingInput = "\(headerBase64).\(payloadBase64)"
        guard let signingData = signingInput.data(using: .utf8) else {
            throw ASCServiceError.jwtGenerationFailed
        }

        let privateKey = try parseP8PrivateKey(credential.privateKey)
        let signature = try privateKey.signature(for: signingData)
        let signatureBase64 = base64URLEncode(signature.rawRepresentation)

        return "\(headerBase64).\(payloadBase64).\(signatureBase64)"
    }

    private func parseP8PrivateKey(_ pem: String) throws -> P256.Signing.PrivateKey {
        let stripped = pem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let keyData = Data(base64Encoded: stripped) else {
            throw ASCServiceError.invalidCredentials
        }

        return try P256.Signing.PrivateKey(derRepresentation: keyData)
    }
}
