// Issue #179 — ASC service errors

import Foundation

public enum ASCServiceError: Error, Sendable, Equatable {
    case notAuthenticated
    case credentialsExpired
    case invalidCredentials
    case jwtGenerationFailed
    case requestFailed(statusCode: Int)
    case decodingFailed
    case noAppLinked
}
