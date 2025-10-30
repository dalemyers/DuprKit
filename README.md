# DuprKit

A Swift package for interacting with the DUPR (Dynamic Universal Pickleball Rating) API.

## Installation

### Swift Package Manager

Add DuprKit to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/dalemyers/DuprKit", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/dalemyers/DuprKit`
3. Select the version you want to use

## Usage

### Authentication

DuprKit supports two authentication methods:

#### Email and Password

```swift
import DuprKit

let auth = DuprEmailPassword(email: "your-email@example.com", password: "your-password")
let dupr = DUPR(auth: auth)

// Get and store the refresh token for future use
let refreshToken = try await dupr.getRefreshToken()
```

#### Refresh Token

```swift
import DuprKit

let auth = DuprRefreshToken(refreshToken: "your-refresh-token")
let dupr = DUPR(auth: auth)
```

### Search for Players

```swift
// Search returns an async stream of results
for try await player in await dupr.searchPlayers(query: "Smith") {
    if let name = player["fullName"] as? String {
        print("Found player: \(name)")
    }
}
```

### Get Player Details

```swift
let playerDetails = try await dupr.getPlayer(playerId: 12345)
print("Player details: \(playerDetails)")
```

### Convert DUPR ID to User ID

```swift
let userId = try await dupr.getUserIdFromDuprId(duprId: "ABC123")
print("User ID: \(userId)")
```

### Search for Clubs

```swift
for try await club in await dupr.searchClubs(query: "Pickleball") {
    if let name = club.name as? String {
        print("Found club: \(name)")
    }
}
```

### Get Club Members

```swift
for try await member in await dupr.getClubMembers(clubId: 12345) {
    if let name = member["fullName"] as? String {
        print("Member: \(name)")
    }
}
```

### Submit a Match

```swift
let matchData: [String: Any] = [
    "date": "2024-01-01",
    "teams": [
        ["players": [123, 456]],
        ["players": [789, 101]]
    ],
    "scores": [[11, 9], [11, 5]]
]

let result = try await dupr.submitMatch(clubId: 12345, matchData: matchData)
print("Match submitted: \(result)")
```

## Error Handling

DuprKit provides comprehensive error types:

```swift
do {
    let player = try await dupr.getPlayer(playerId: 12345)
} catch DuprError.httpError(let message, let statusCode, let body) {
    print("HTTP Error \(statusCode): \(message)")
} catch DuprError.authenticationFailed(let message) {
    print("Authentication failed: \(message)")
} catch DuprError.networkError(let error) {
    print("Network error: \(error)")
} catch {
    print("Other error: \(error)")
}
```

### Error Types

- `httpError(message:statusCode:responseBody:)` - HTTP request failures
- `authenticationFailed(message:)` - Authentication problems
- `invalidToken(message:)` - Token validation issues
- `invalidInput(message:)` - Invalid input parameters
- `networkError(Error)` - Network connectivity issues
- `decodingError(Error)` - JSON decoding failures
- `unknown(String)` - Other unexpected errors

## Testing

DuprKit includes comprehensive test coverage with both unit tests (using mocks) and integration tests (using the real API).

See [Tests/README.md](Tests/README.md) for detailed testing documentation.

### Running Tests

```bash
# Run all tests
swift test

# Run only unit tests (no credentials needed)
swift test --filter unit

# Run only integration tests (requires credentials)
swift test --filter integration

# Format and lint before testing
make test
```

## Code Quality

This project uses SwiftLint and SwiftFormat to maintain code quality and consistency.

```bash
# Format code
make format

# Run linter
make lint

# Format and lint before committing
make pre-commit
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed information about code quality tools and custom linting rules.

## Dependencies

- [DictionaryCoder](https://github.com/dalemyers/DictionaryCoder) - For dictionary-based encoding/decoding

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
