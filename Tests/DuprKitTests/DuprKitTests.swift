import Testing
@testable import DuprKit

/// Example test - see IntegrationTests.swift and UnitTests.swift for comprehensive test suites
@Test func example() {
    // This is a simple example test
    // Run all tests with: swift test
    // Run only unit tests: swift test --filter unit
    // Run only integration tests: swift test --filter integration

    let auth = DuprEmailPassword(email: "test@example.com", password: "password")
    #expect(auth.email == "test@example.com")
}
