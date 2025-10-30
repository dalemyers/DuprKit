# DuprKit Tests

This directory contains comprehensive tests for the DuprKit library, organized into two types:

## Test Types

### Unit Tests (`UnitTests.swift`)
Unit tests use mocks and don't require API credentials. They test:
- Data structure initialization
- Error handling and formatting
- Mock data generators
- Test environment utilities

Run only unit tests:
```bash
swift test --filter unit
```

### Integration Tests (`IntegrationTests.swift`)
Integration tests connect to the real DUPR API and require valid credentials. They test:
- Authentication with email/password
- Authentication with refresh token
- Player search functionality
- Club search functionality
- Getting player details
- Getting club members
- DUPR ID lookups

Run only integration tests:
```bash
swift test --filter integration
```

## Setup for Integration Tests

### Quick Start

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your DUPR email and password:
   ```
   DUPR_EMAIL=your-email@example.com
   DUPR_PASSWORD=your-password
   ```

3. Run tests - the refresh token will be generated automatically!
   ```bash
   swift test --filter integration
   ```

The `.env` file is in `.gitignore` to prevent accidentally committing credentials.

### Automatic Refresh Token Management

The test suite automatically manages refresh tokens for you:

**Email/Password Authentication Test:**
- Authenticates using your email and password
- Retrieves a refresh token from the API
- **Automatically stores the token in your `.env` file**
- You'll see: `✓ Stored refresh token in .env file`

**Refresh Token Authentication Test:**
- First checks if `DUPR_REFRESH_TOKEN` exists in `.env`
- If missing but email/password are available, automatically runs email/password auth first
- Then validates the refresh token works
- You'll see: `ℹ️  No refresh token found, running email/password authentication first...`

This means you only need to provide email and password - the refresh token is generated and persisted automatically!

### Optional Test IDs

For specific integration tests, you can add:
```
DUPR_TEST_CLUB_ID=12345
DUPR_TEST_USER_ID=67890
DUPR_TEST_DUPR_ID=ABC123
```

## Test Tags

Tests are tagged for easy filtering:

- `unit` - Unit tests using mocks
- `integration` - Integration tests using real API
- `auth` - Authentication-related tests
- `search` - Search functionality tests
- `player` - Player-related tests
- `club` - Club-related tests
- `mock` - Mock data generator tests
- `error` - Error handling tests
- `environment` - Environment utility tests

## Writing New Tests

### Adding a Unit Test

```swift
@Test("Test description", .tags(.unit))
func testSomething() {
    // Your test code
    #expect(someValue == expectedValue)
}
```

### Adding an Integration Test

```swift
@Test("Test description", .tags(.integration))
func testSomethingWithAPI() async throws {
    let dupr = try makeAuthenticatedClient()
    
    let result = try await dupr.someMethod()
    #expect(result != nil)
}
```

### Skipping Tests Conditionally

```swift
@Test("Test description", .tags(.integration))
func testWithOptionalData() async throws {
    guard let testId = TestEnvironment.shared.get("DUPR_TEST_ID") else {
        throw XCTSkip("Skipping: DUPR_TEST_ID not set")
    }
    
    // Test code using testId
}
```

## Continuous Integration

For CI environments, you can set environment variables directly instead of using a `.env` file:

```bash
export DUPR_EMAIL="ci-test@example.com"
export DUPR_PASSWORD="ci-password"
swift test
```

Or skip integration tests in CI:

```bash
swift test --filter unit  # Only run unit tests
```
