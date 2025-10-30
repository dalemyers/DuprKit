import Foundation
import os.log

/// A DUPR API Wrapper
public actor DUPR {
    private let logger: Logger
    private let httpClient: DuprHTTPClient

    public init(auth: DuprAuth, logger: Logger? = nil) {
        if let logger {
            self.logger = logger
        } else {
            self.logger = Logger(subsystem: "com.dupr", category: "dupr")
        }

        self.httpClient = DuprHTTPClient(auth: auth, logger: self.logger)
    }

    // MARK: - Private Helper Methods

    /// Decode JSON data and extract the result dictionary
    private func getResult(from response: [String: Any], errorMessage: String = "Failed to get results from data.") throws -> [String: Any] {
        guard let result = response["result"] as? [String: Any] else {
            throw DuprError.decodingError(NSError(domain: "DuprKit", code: -1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ]))
        }
        return result
    }

    /// Decode JSON data and extract hits array from result
    private func getHits(from response: [String: Any], errorMessage: String = "Failed to decode data.") throws -> [[String: Any]] {
        let result = try getResult(from: response, errorMessage: errorMessage)
        guard let hits = result["hits"] as? [[String: Any]] else {
            return []
        }
        return hits
    }

    /// Decode JSON data as a dictionary
    private func decodeJSON(from data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DuprError.decodingError(NSError(domain: "DuprKit", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode JSON: \(String(describing: String(data: data, encoding: .utf8)))"
            ]))
        }
        return json
    }

    // MARK: - Public API Methods

    /// Get all members of a club
    /// - Parameter clubId: The ID of the club
    /// - Returns: An async sequence of all members
    public func getClubMembers(clubId: Int) -> AsyncThrowingStream<Player, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var offset = 0
                    let limit = 25 // 25 is the max allowed by the API

                    while true {
                        let body: [String: Any] = [
                            "offset": offset,
                            "limit": limit,
                            "query": "*"
                        ]

                        let data = try await self.httpClient.post(
                            requestPath: "/club/\(clubId)/members/v1.0/all",
                            jsonData: body
                        )

                        let json = try self.decodeJSON(from: data)
                        let hits = try self.getHits(from: json)

                        if hits.isEmpty {
                            continuation.finish()
                            return
                        }

                        for hit in hits {
                            continuation.yield(try Player.fromData(data: hit))
                        }

                        offset += limit
                    }
                } catch {
                    print(error)
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Search for players
    /// - Parameter query: The value to search for
    /// - Returns: An async sequence of all matching members
    public func searchPlayers(query: String) -> AsyncThrowingStream<Player, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var offset = 0
                    let limit = 25 // 25 is the max allowed by the API

                    while true {
                        let body: [String: Any] = [
                            "filter": [:],
                            "limit": limit,
                            "query": query
                        ]

                        let data = try await self.httpClient.post(
                            requestPath: "/player/v1.0/search",
                            jsonData: body
                        )

                        let json = try self.decodeJSON(from: data)
                        let hits = try self.getHits(from: json)

                        if hits.isEmpty {
                            continuation.finish()
                            return
                        }

                        for hit in hits {
                            continuation.yield(try Player.fromData(data: hit))
                        }

                        offset += limit
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Get a player's info
    /// - Parameter playerId: The ID of the player. This is not the same as the share ID.
    /// - Returns: The player's information as a dictionary
    public func getPlayer(playerId: Int) async throws -> Player {
        let data = try await httpClient.get(requestPath: "/player/v1.0/\(playerId)")
        let json = try self.decodeJSON(from: data)
        return try Player.fromData(data: getResult(from: json, errorMessage: "Failed to decode player response"))
    }

    /// Convert a 6-character DUPR ID to a user ID
    /// - Parameter duprId: The 6-character DUPR ID
    /// - Returns: The user ID
    public func getUserIdFromDuprId(duprId: String) async throws -> Int {
        let body: [String: Any] = [
            "duprId": duprId
        ]

        let data = try await httpClient.post(
            requestPath: "/player/search/byDuprId",
            jsonData: body
        )
        
        let json = try self.decodeJSON(from: data)
        let results = json["results"] as! [[String:Any]]

        guard let firstResult = results.first else {
            throw DuprError.decodingError(NSError(domain: "DuprKit", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get result from DUPR ID response"
            ]))
        }
        
        guard let userId = firstResult["userId"] as? Int else {
            throw DuprError.decodingError(NSError(domain: "DuprKit", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get user ID from DUPR ID response"
            ]))
        }

        return userId
    }

    /// Search for clubs
    /// - Parameter query: The search query
    /// - Returns: An async sequence of all matching clubs
    public func searchClubs(query: String) -> AsyncThrowingStream<Club, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var offset = 0
                    let limit = 25

                    while true {
                        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
                        let data = try await self.httpClient.get(
                            requestPath: "/club/v1.0/all?q=\(encodedQuery)&own=false&offset=\(offset)&limit=\(limit)"
                        )
                        
                        let json = try decodeJSON(from: data)
                        let clubs = try getHits(from: json)
                        
                        if clubs.isEmpty {
                            continuation.finish()
                            return
                        }

                        for club in clubs {
                            continuation.yield(try Club.fromData(data: club))
                        }

                        offset += limit

                        let hasMore = json["hasMore"] as? Bool ?? false

                        guard hasMore else {
                            continuation.finish()
                            return
                        }
                    }
                } catch {
                    print(error)
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Submit a match to DUPR
    /// - Parameters:
    ///   - clubId: The club ID (optional)
    ///   - matchData: The match data as a dictionary
    /// - Returns: The response data
    public func submitMatch(clubId: Int?, matchData: [String: Any]) async throws -> [String: Any] {
        let path: String
        if let clubId {
            path = "/club/\(clubId)/match/v1.0/save"
        } else {
            // For matches without a club, we might need a different endpoint
            // For now, throw an error
            throw DuprError.invalidInput(message: "Club ID is required for match submission")
        }

        let data = try await httpClient.put(
            requestPath: path,
            jsonData: matchData
        )

        return try self.decodeJSON(from: data)
    }

    /// Get the refresh token from the HTTP client
    /// This is needed to store it in the keychain
    public func getRefreshToken() async throws -> String {
        try await self.httpClient.getRefreshToken()
    }
}
