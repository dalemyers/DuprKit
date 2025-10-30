import Foundation
import Testing
@testable import DuprKit

/// Unit tests using mocks - these don't require API credentials
/// Run with: swift test --filter DuprUnitTests
@Suite("DUPR Unit Tests", .tags(.unit))
struct DuprUnitTests {
    // MARK: - Authentication Tests

    @Test("Email password auth struct initialization", .tags(.unit, .auth))
    func emailPasswordAuthInit() {
        let auth = DuprEmailPassword(email: "test@example.com", password: "password123")
        #expect(auth.email == "test@example.com")
        #expect(auth.password == "password123")
    }

    @Test("Refresh token auth struct initialization", .tags(.unit, .auth))
    func refreshTokenAuthInit() {
        let auth = DuprRefreshToken(refreshToken: "test_token_123")
        #expect(auth.refreshToken == "test_token_123")
    }

    // MARK: - Error Tests

    @Test("HTTP error formatting", .tags(.unit, .error))
    func httpErrorDescription() {
        let error = DuprError.httpError(
            message: "Request failed",
            statusCode: 404,
            responseBody: "Not found"
        )

        let description = error.localizedDescription
        #expect(description.contains("Request failed"))
        #expect(description.contains("404"))
        #expect(description.contains("Not found"))
    }

    @Test("Authentication error formatting", .tags(.unit, .error))
    func authenticationErrorDescription() {
        let error = DuprError.authenticationFailed(message: "Invalid credentials")
        let description = error.localizedDescription
        #expect(description.contains("Authentication failed"))
        #expect(description.contains("Invalid credentials"))
    }

    @Test("Invalid token error formatting", .tags(.unit, .error))
    func invalidTokenErrorDescription() {
        let error = DuprError.invalidToken(message: "Token expired")
        let description = error.localizedDescription
        #expect(description.contains("Invalid token"))
        #expect(description.contains("Token expired"))
    }

    @Test("Invalid input error formatting", .tags(.unit, .error))
    func invalidInputErrorDescription() {
        let error = DuprError.invalidInput(message: "Missing required field")
        let description = error.localizedDescription
        #expect(description.contains("Invalid input"))
        #expect(description.contains("Missing required field"))
    }

    @Test("Network error formatting", .tags(.unit, .error))
    func networkErrorDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Connection timeout",
        ])
        let error = DuprError.networkError(underlyingError)
        let description = error.localizedDescription
        #expect(description.contains("Network error"))
    }

    @Test("Decoding error formatting", .tags(.unit, .error))
    func decodingErrorDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Invalid JSON",
        ])
        let error = DuprError.decodingError(underlyingError)
        let description = error.localizedDescription
        #expect(description.contains("Decoding error"))
    }

    @Test("Unknown error formatting", .tags(.unit, .error))
    func unknownErrorDescription() {
        let error = DuprError.unknown("Something went wrong")
        let description = error.localizedDescription
        #expect(description.contains("Unknown error"))
        #expect(description.contains("Something went wrong"))
    }

    // MARK: - Mock Data Generator Tests

    @Test("Mock login response generation", .tags(.unit, .mock))
    func mockLoginResponse() {
        let response = MockDataGenerator.loginResponse(
            accessToken: "test_access",
            refreshToken: "test_refresh"
        )

        guard let result = response["result"] as? [String: String] else {
            Issue.record("Result should be a dictionary")
            return
        }

        #expect(result["accessToken"] == "test_access")
        #expect(result["refreshToken"] == "test_refresh")
    }

    @Test("Mock player search results generation", .tags(.unit, .mock))
    func mockPlayerSearchResults() {
        let response = MockDataGenerator.playerSearchResults(count: 3)

        guard let result = response["result"] as? [String: Any],
              let hits = result["hits"] as? [[String: Any]]
        else {
            Issue.record("Should have result with hits array")
            return
        }

        #expect(hits.count == 3)
        #expect(result["total"] as? Int == 3)

        // Check first player structure
        let firstPlayer = hits[0]
        #expect(firstPlayer["id"] as? Int == 1)
        #expect(firstPlayer["fullName"] as? String == "Player 1")
    }

    @Test("Mock club members results generation", .tags(.unit, .mock))
    func mockClubMembersResults() {
        let response = MockDataGenerator.clubMembersResults(count: 5)

        guard let result = response["result"] as? [String: Any],
              let hits = result["hits"] as? [[String: Any]]
        else {
            Issue.record("Should have result with hits array")
            return
        }

        #expect(hits.count == 5)

        // Check member structure
        let firstMember = hits[0]
        #expect(firstMember["id"] as? Int == 1)
        #expect(firstMember["role"] as? String == "member")
    }

    @Test("Mock club search results generation", .tags(.unit, .mock))
    func mockClubSearchResults() {
        let response = MockDataGenerator.clubSearchResults(count: 4)

        guard let result = response["result"] as? [String: Any],
              let hits = result["hits"] as? [[String: Any]]
        else {
            Issue.record("Should have result with hits array")
            return
        }

        #expect(hits.count == 4)
        #expect(result["hasMore"] as? Bool == false)

        // Check club structure
        let firstClub = hits[0]
        #expect(firstClub["name"] as? String == "Club 1")
        #expect(firstClub["memberCount"] as? Int == 11)
    }

    @Test("Mock player details generation", .tags(.unit, .mock))
    func mockPlayerDetails() {
        let response = MockDataGenerator.playerDetails(playerId: 42)

        guard let result = response["result"] as? [String: Any] else {
            Issue.record("Should have result dictionary")
            return
        }

        #expect(result["id"] as? Int == 42)
        #expect(result["fullName"] as? String == "Test Player")

        guard let ratings = result["ratings"] as? [String: Double] else {
            Issue.record("Should have ratings dictionary")
            return
        }

        #expect(ratings["doubles"] == 5.0)
        #expect(ratings["singles"] == 4.8)
    }

    @Test("Mock DUPR ID lookup result generation", .tags(.unit, .mock))
    func mockDuprIdLookup() {
        let response = MockDataGenerator.duprIdLookupResult(userId: 123, duprId: "ABC456")

        guard let results = response["results"] as? [[String: Any]],
              let firstResult = results.first
        else {
            Issue.record("Should have results array")
            return
        }

        #expect(firstResult["userId"] as? Int == 123)
        #expect(firstResult["duprId"] as? String == "ABC456")
    }

    @Test("Mock match submission response generation", .tags(.unit, .mock))
    func mockMatchSubmission() {
        let response = MockDataGenerator.matchSubmissionResponse(matchId: 999)

        guard let result = response["result"] as? [String: Any] else {
            Issue.record("Should have result dictionary")
            return
        }

        #expect(result["matchId"] as? Int == 999)
        #expect(result["status"] as? String == "pending")
    }

    // MARK: - Test Environment Tests

    @Test("Test environment initialization", .tags(.unit, .environment))
    func environmentInit() {
        // Environment should initialize without crashing
        #expect(
            Environment.get("PATH") != nil || Environment.get("HOME") != nil,
            "Should have at least some environment variables"
        )
    }

    @Test("Test environment get method", .tags(.unit, .environment))
    func environmentGet() {
        // Test getting a non-existent variable
        let nonExistent = Environment.get("DUPR_NONEXISTENT_VAR_12345")
        #expect(nonExistent == nil, "Non-existent variable should return nil")
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var unit: Self
    @Tag static var mock: Self
    @Tag static var error: Self
    @Tag static var environment: Self
}
