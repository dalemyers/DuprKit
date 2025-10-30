import Foundation
import Testing
@testable import DuprKit

/// Integration tests that connect to the real DUPR API
/// These tests require valid credentials in a .env file
/// Run with: swift test --filter DuprIntegrationTests
@Suite("DUPR Integration Tests", .tags(.integration))
struct DuprIntegrationTests {
    // MARK: - Authentication Tests

    @Test("Authentication with email and password", .tags(.integration, .auth))
    func emailPasswordAuthentication() async throws {
        guard Environment.hasCredentials else {
            throw XCTSkip("Skipping integration test: DUPR_EMAIL and DUPR_PASSWORD not set in .env file")
        }

        let email = try Environment.require("DUPR_EMAIL")
        let password = try Environment.require("DUPR_PASSWORD")

        let auth = DuprEmailPassword(email: email, password: password)
        let dupr = DUPR(auth: auth)

        // Try to get refresh token to verify authentication works
        let refreshToken = try await dupr.getRefreshToken()
        #expect(!refreshToken.isEmpty, "Refresh token should not be empty")

        // Store the refresh token in .env file for future tests
        do {
            try Environment.set("DUPR_REFRESH_TOKEN", value: refreshToken)
            print("✓ Stored refresh token in .env file")
        } catch {
            print("⚠️  Warning: Could not store refresh token in .env file: \(error)")
        }
    }

    @Test("Authentication with refresh token", .tags(.integration, .auth))
    func refreshTokenAuthentication() async throws {
        // If refresh token is not set but we have credentials, run email/password auth first
        if !Environment.hasRefreshToken, Environment.hasCredentials {
            print("ℹ️  No refresh token found, running email/password authentication first...")
            try await emailPasswordAuthentication()
        }

        guard Environment.hasRefreshToken else {
            throw XCTSkip("Skipping integration test: DUPR_REFRESH_TOKEN not set in .env file")
        }

        let refreshToken = try Environment.require("DUPR_REFRESH_TOKEN")

        let auth = DuprRefreshToken(refreshToken: refreshToken)
        let dupr = DUPR(auth: auth)

        // Try to get refresh token to verify authentication works
        let token = try await dupr.getRefreshToken()
        #expect(!token.isEmpty, "Refresh token should not be empty")
    }

    // MARK: - Player Search Tests

    @Test("Search for players", .tags(.integration, .search))
    func testSearchPlayers() async throws {
        let dupr = try makeAuthenticatedClient()

        var playerCount = 0
        var firstPlayer: Player?

        for try await player in await dupr.searchPlayers(query: "Smith") {
            playerCount += 1
            if firstPlayer == nil {
                firstPlayer = player
            }

            // Limit results for testing
            if playerCount >= 5 {
                break
            }
        }

        #expect(playerCount > 0, "Should find at least one player")
        #expect(firstPlayer != nil, "Should have at least one player result")
    }

    @Test("Get player by ID", .tags(.integration, .player))
    func getPlayerById() async throws {
        let dupr = try makeAuthenticatedClient()

        // First search for a player to get an ID
        var playerId: Int?
        for try await player in await dupr.searchPlayers(query: "test") {
            playerId = player.id
            break
        }

        guard let id = playerId else {
            throw XCTSkip("Could not find a player ID for testing")
        }

        let playerDetails = try await dupr.getPlayer(playerId: id)
        #expect(playerDetails.id == id, "Player ID should match")
    }

    @Test("Convert DUPR ID to user ID", .tags(.integration, .player))
    func testGetUserIdFromDuprId() async throws {
        guard let duprId = Environment.get("DUPR_TEST_DUPR_ID") else {
            throw XCTSkip("Skipping: DUPR_TEST_DUPR_ID not set in .env file")
        }

        let dupr = try makeAuthenticatedClient()
        let userId = try await dupr.getUserIdFromDuprId(duprId: duprId)

        #expect(userId > 0, "User ID should be positive")
    }

    // MARK: - Club Tests

    @Test("Search for clubs", .tags(.integration, .club))
    func testSearchClubs() async throws {
        let dupr = try makeAuthenticatedClient()

        var clubCount = 0
        var firstClub: Club?

        for try await club in await dupr.searchClubs(query: "Pickleball") {
            clubCount += 1
            if firstClub == nil {
                firstClub = club
            }

            // Limit results for testing
            if clubCount >= 5 {
                break
            }
        }

        #expect(clubCount > 0, "Should find at least one club")
        #expect(firstClub != nil, "Should have at least one club result")
    }

    @Test("Get club members", .tags(.integration, .club))
    func testGetClubMembers() async throws {
        guard let clubIdString = Environment.get("DUPR_TEST_CLUB_ID"),
              let clubId = Int(clubIdString)
        else {
            throw XCTSkip("Skipping: DUPR_TEST_CLUB_ID not set in .env file")
        }

        let dupr = try makeAuthenticatedClient()

        var memberCount = 0
        var firstMember: Player?

        for try await member in await dupr.getClubMembers(clubId: clubId) {
            memberCount += 1
            if firstMember == nil {
                firstMember = member
            }

            // Limit results for testing
            if memberCount >= 5 {
                break
            }
        }

        #expect(memberCount > 0, "Should find at least one club member")
        #expect(firstMember != nil, "Should have at least one member result")
    }

    // MARK: - Helper Methods

    private func makeAuthenticatedClient() throws -> DUPR {
        if Environment.hasRefreshToken {
            let refreshToken = try Environment.require("DUPR_REFRESH_TOKEN")
            return DUPR(auth: DuprRefreshToken(refreshToken: refreshToken))
        } else if Environment.hasCredentials {
            let email = try Environment.require("DUPR_EMAIL")
            let password = try Environment.require("DUPR_PASSWORD")
            return DUPR(auth: DuprEmailPassword(email: email, password: password))
        } else {
            throw XCTSkip("No credentials available. Set DUPR_EMAIL/DUPR_PASSWORD or DUPR_REFRESH_TOKEN in .env file")
        }
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var integration: Self
    @Tag static var auth: Self
    @Tag static var search: Self
    @Tag static var player: Self
    @Tag static var club: Self
}

// MARK: - XCTSkip Helper

struct XCTSkip: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
