import Foundation
import DictionaryCoder

public struct Profile: Codable, Hashable {
    public let userId: Int
    public let duprId: String?
    public let fullName: String
    public let firstName: String?
    public let lastName: String?
    public let singlesRating: Double?
    public let doublesRating: Double?
    public let profileImageUrl: String?

    public var displayRating: Double? {
        self.doublesRating ?? self.singlesRating
    }

    public var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        }
        return self.fullName
    }
    
    public static func fromData(data: [String: Any]) throws -> Profile {
        return try DictionaryDecoder().decode(Profile.self, from: data)
    }
}
