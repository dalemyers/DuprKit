import Foundation
@testable import DuprKit

/// Mock URLProtocol for intercepting network requests in tests
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
    static var responses: [String: MockResponse] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol handler is not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Nothing to do
    }

    static func reset() {
        self.requestHandler = nil
        self.responses = [:]
    }

    static func mockResponse(for path: String, statusCode: Int = 200, json: [String: Any]) {
        self.responses[path] = MockResponse(statusCode: statusCode, json: json)
    }

    static func mockResponse(for path: String, statusCode: Int = 200, data: Data) {
        self.responses[path] = MockResponse(statusCode: statusCode, data: data)
    }
}

struct MockResponse {
    let statusCode: Int
    let data: Data

    init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }

    init(statusCode: Int, json: [String: Any]) {
        self.statusCode = statusCode
        self.data = try! JSONSerialization.data(withJSONObject: json)
    }
}

/// Helper to create a mock URLSession for testing
extension URLSession {
    static func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

/// Mock data generators for common API responses
enum MockDataGenerator {
    static func loginResponse(
        accessToken: String = "mock_access_token",
        refreshToken: String = "mock_refresh_token"
    ) -> [String: Any] {
        [
            "result": [
                "accessToken": accessToken,
                "refreshToken": refreshToken,
            ],
        ]
    }

    static func refreshResponse(accessToken: String = "mock_access_token") -> [String: Any] {
        [
            "result": accessToken,
        ]
    }

    static func playerSearchResults(count: Int = 5) -> [String: Any] {
        var hits: [[String: Any]] = []

        for i in 1...count {
            hits.append([
                "id": i,
                "fullName": "Player \(i)",
                "email": "player\(i)@example.com",
                "ratings": [
                    "doubles": 4.5 + Double(i) * 0.1,
                    "singles": 4.3 + Double(i) * 0.1,
                ],
            ])
        }

        return [
            "result": [
                "hits": hits,
                "total": count,
            ],
        ]
    }

    static func clubMembersResults(count: Int = 5) -> [String: Any] {
        var hits: [[String: Any]] = []

        for i in 1...count {
            hits.append([
                "id": i,
                "fullName": "Member \(i)",
                "email": "member\(i)@example.com",
                "role": "member",
            ])
        }

        return [
            "result": [
                "hits": hits,
                "total": count,
            ],
        ]
    }

    static func clubSearchResults(count: Int = 5) -> [String: Any] {
        var hits: [[String: Any]] = []

        for i in 1...count {
            hits.append([
                "id": i,
                "name": "Club \(i)",
                "description": "Test club \(i)",
                "memberCount": 10 + i,
            ])
        }

        return [
            "result": [
                "hits": hits,
                "hasMore": false,
            ],
        ]
    }

    static func playerDetails(playerId: Int) -> [String: Any] {
        [
            "result": [
                "id": playerId,
                "fullName": "Test Player",
                "email": "test@example.com",
                "ratings": [
                    "doubles": 5.0,
                    "singles": 4.8,
                ],
                "location": [
                    "city": "San Francisco",
                    "state": "CA",
                ],
            ],
        ]
    }

    static func duprIdLookupResult(userId: Int, duprId: String) -> [String: Any] {
        [
            "results": [
                [
                    "userId": userId,
                    "duprId": duprId,
                    "fullName": "Test User",
                ],
            ],
        ]
    }

    static func matchSubmissionResponse(matchId: Int = 12345) -> [String: Any] {
        [
            "result": [
                "matchId": matchId,
                "status": "pending",
                "message": "Match submitted successfully",
            ],
        ]
    }
}
