// Issue #185 — App Store Connect API client with JWT authentication

import Foundation
import CryptoKit
import HelaiaLogger

// MARK: - Protocol

public protocol ASCAPIClientProtocol: Sendable {
    func fetchApps(credential: ASCCredential) async throws -> [ASCApp]
    func validateCredentials(_ credential: ASCCredential) async throws -> Bool
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
