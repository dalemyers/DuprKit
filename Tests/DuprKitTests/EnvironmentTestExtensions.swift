import Foundation

/// Helper for loading environment variables from .env file for integration tests
extension Environment {
    static func require(_ key: String) throws -> String {
        guard let value = get(key) else {
            throw TestEnvironmentError.missingVariable(key)
        }

        return value
    }

    static var hasCredentials: Bool {
        return get("DUPR_EMAIL") != nil && get("DUPR_PASSWORD") != nil
    }

    static var hasRefreshToken: Bool {
        return get("DUPR_REFRESH_TOKEN") != nil
    }
}

enum TestEnvironmentError: Error {
    case missingVariable(String)
}

extension TestEnvironmentError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .missingVariable(key):
            "Missing required environment variable: \(key). Please create a .env file based on .env.example"
        }
    }
}
