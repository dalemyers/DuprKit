import Foundation

/// Protocol for DUPR authentication methods
public protocol DuprAuth: Sendable { }

/// DUPR authentication using email and password
public struct DuprEmailPassword: DuprAuth, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

/// DUPR authentication using a refresh token
public struct DuprRefreshToken: DuprAuth, Sendable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
