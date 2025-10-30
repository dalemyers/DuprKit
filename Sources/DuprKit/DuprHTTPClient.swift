import Foundation
import os.log

/// HTTP client for the DUPR API
actor DuprHTTPClient {
    static let apiHost = "https://api.dupr.gg"

    private let logger: Logger
    private var username: String?
    private var password: String?
    private var accessToken: String?
    private var refreshToken: String?
    private let cacheTokens: Bool
    private let session: URLSession

    private var tokensPath: URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let duprDirectory = cacheDirectory.appendingPathComponent("dupr", isDirectory: true)
        return duprDirectory.appendingPathComponent(".tokens")
    }

    init(auth: DuprAuth, cacheTokens: Bool = true, logger: Logger) {
        self.logger = logger
        self.cacheTokens = cacheTokens
        self.session = URLSession.shared

        if let emailPassword = auth as? DuprEmailPassword {
            self.username = emailPassword.email
            self.password = emailPassword.password
            self.refreshToken = nil
        } else if let tokenAuth = auth as? DuprRefreshToken {
            self.refreshToken = tokenAuth.refreshToken
        }
    }

    /// Get the expiry date of a JWT token
    private func getExpiryDate(token: String) throws -> Date {
        let components = token.split(separator: ".")
        guard components.count == 3 else {
            throw DuprError.invalidToken(message: "Invalid token format")
        }

        var payloadB64 = String(components[1])
        let paddingLength = 4 - (payloadB64.count % 4)
        if paddingLength < 4 {
            payloadB64 += String(repeating: "=", count: paddingLength)
        }

        guard let payloadData = Data(base64Encoded: payloadB64),
              let payloadString = String(data: payloadData, encoding: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: Data(payloadString.utf8)) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval
        else {
            throw DuprError.invalidToken(message: "Could not decode token payload")
        }

        return Date(timeIntervalSince1970: exp)
    }

    /// Refresh authentication tokens
    func refreshTokens() async throws -> (accessToken: String, refreshToken: String) {
        // Try to load cached tokens if enabled
        if self.cacheTokens, FileManager.default.fileExists(atPath: self.tokensPath.path) {
            if let data = try? Data(contentsOf: tokensPath),
               let tokenData = try? JSONDecoder().decode(TokenResponse.self, from: data)
            {
                let accessExpiry = try getExpiryDate(token: tokenData.accessToken)
                let refreshExpiry = try getExpiryDate(token: tokenData.refreshToken)

                if accessExpiry > Date().addingTimeInterval(60) {
                    accessToken = tokenData.accessToken
                } else {
                    accessToken = nil
                }

                if refreshExpiry > Date().addingTimeInterval(60) {
                    refreshToken = tokenData.refreshToken
                } else {
                    refreshToken = nil
                }
            }
        }

        // If we have valid cached tokens, return them
        if let accessToken, let refreshToken {
            return (accessToken, refreshToken)
        }

        // If we have a refresh token, use it to get a new access token
        if let refreshToken {
            var request = URLRequest(url: URL(string: Self.apiHost + "/auth/v1.0/refresh")!)
            request.httpMethod = "GET"
            request.setValue(refreshToken, forHTTPHeaderField: "x-refresh-token")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw DuprError.networkError(NSError(domain: "DuprKit", code: -1))
            }

            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw DuprError.httpError(
                    message: "Failed to refresh token",
                    statusCode: httpResponse.statusCode,
                    responseBody: body
                )
            }

            let result = try JSONDecoder().decode(RefreshResponse.self, from: data)
            accessToken = result.result

            return (result.result, refreshToken)
        }

        // Otherwise, login with email and password
        guard let username, let password else {
            throw DuprError.authenticationFailed(message: "No credentials available")
        }

        var request = URLRequest(url: URL(string: Self.apiHost + "/auth/v1.0/login")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginBody = ["email": username, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DuprError.networkError(NSError(domain: "DuprKit", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DuprError.httpError(
                message: "Failed to authenticate",
                statusCode: httpResponse.statusCode,
                responseBody: body
            )
        }

        let result = try JSONDecoder().decode(LoginResponse.self, from: data)
        accessToken = result.result.accessToken
        refreshToken = result.result.refreshToken

        // Cache tokens if enabled
        if self.cacheTokens {
            let directory = self.tokensPath.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let tokenData = try JSONEncoder().encode(result.result)
            try? tokenData.write(to: self.tokensPath)
        }

        return (result.result.accessToken, result.result.refreshToken)
    }

    /// Perform a GET request
    func get(requestPath: String) async throws -> Data {
        let tokens = try await refreshTokens()

        var request = URLRequest(url: URL(string: Self.apiHost + requestPath)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DuprError.networkError(NSError(domain: "DuprKit", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DuprError.httpError(
                message: "GET request failed",
                statusCode: httpResponse.statusCode,
                responseBody: body
            )
        }

        return data
    }

    /// Perform a POST request
    func post(requestPath: String, jsonData: Any?) async throws -> Data {
        let tokens = try await refreshTokens()

        var request = URLRequest(url: URL(string: Self.apiHost + requestPath)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let jsonData {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonData)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DuprError.networkError(NSError(domain: "DuprKit", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DuprError.httpError(
                message: "POST request failed",
                statusCode: httpResponse.statusCode,
                responseBody: body
            )
        }

        return data
    }

    /// Perform a PUT request
    func put(requestPath: String, jsonData: Any?) async throws -> Data {
        let tokens = try await refreshTokens()

        var request = URLRequest(url: URL(string: Self.apiHost + requestPath)!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let jsonData {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonData)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DuprError.networkError(NSError(domain: "DuprKit", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DuprError.httpError(
                message: "PUT request failed",
                statusCode: httpResponse.statusCode,
                responseBody: body
            )
        }

        return data
    }

    /// Get the current refresh token
    func getRefreshToken() async throws -> String {
        let tokens = try await refreshTokens()
        return tokens.refreshToken
    }
}

// MARK: - Response Models

private struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

private struct RefreshResponse: Codable {
    let result: String
}

private struct LoginResponse: Codable {
    let result: TokenResponse
}
