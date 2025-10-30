import Foundation

/// Base error type for all DUPR errors
public enum DuprError: Error {
    case httpError(message: String, statusCode: Int, responseBody: String)
    case authenticationFailed(message: String)
    case invalidToken(message: String)
    case invalidInput(message: String)
    case networkError(Error)
    case decodingError(Error)
    case unknown(String)
}

extension DuprError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .httpError(message, statusCode, responseBody):
            "\(message), status_code=\(statusCode), text=\(responseBody)"
        case let .authenticationFailed(message):
            "Authentication failed: \(message)"
        case let .invalidToken(message):
            "Invalid token: \(message)"
        case let .invalidInput(message):
            "Invalid input: \(message)"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case let .decodingError(error):
            "Decoding error: \(error.localizedDescription)"
        case let .unknown(message):
            "Unknown error: \(message)"
        }
    }
}
