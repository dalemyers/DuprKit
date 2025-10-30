import Foundation
import DictionaryCoder

public struct Player: Codable, Hashable, Identifiable {
    public let age: Int?
    public let birthdate: String?
    public let created: String?
    public let defaultRating: String?
    public let displayUsername: Bool?
    public let distance: String?
    public let distanceInMiles: Double?
    public let doubles: String?
    public let doublesProvisional: Bool?
    public let doublesReliability: Double?
    public let doublesVerified: String?
    public let email: String? // Defined as required in the spec, but clearly isn't.
    public let enablePrivacy: Bool
    public let firstName: String?
    public let formattedAddress: String?
    public let fullName: String
    public let gender: String?
    public let hand: String?
    public let id: Int
    public let imageUrl: String?
    public let isoAlpha2Code: String?
    public let lastName: String?
    public let latitude: Double?
    public let location: String?
    public let longitude: Double?
    public let lucraConnected: Bool?
    public let phone: String?
    public let provisionalDoublesRating: Double?
    public let provisionalSinglesRating: Double?
    public let referralCode: String?
    public let registered: Bool?
    public let registrationType: String?
    public let reliabilityScore: Int?
    public let shortAddress: String?
    public let singles: String?
    public let singlesProvisional: Bool?
    public let singlesReliability: Double?
    public let singlesVerified: String?
    public let sponsor: Sponsor?
    public let status: String?
    public let username: String?
    public let verifiedEmail: Bool
    public let verifiedPhone: Bool?

    public static func fromData(data: [String: Any]) throws -> Self {
        try DictionaryDecoder().decode(Self.self, from: data)
    }
}
