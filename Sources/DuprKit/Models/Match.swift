import Foundation
import DictionaryCoder

public struct Match: Codable {
    public let eventDate: String
    public let format: String // "SINGLES" or "DOUBLES"
    public let matchType: String // "SIDE_ONLY" or "RALLY"
    public let team1: Team
    public let team2: Team
    public let scores: [Score]
    public let clubId: Int?
    public let notify: Bool
    public let metadata: [String: String]
    
    public static func fromData(data: [String: Any]) throws -> Match {
        return try DictionaryDecoder().decode(Match.self, from: data)
    }
}
