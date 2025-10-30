import Foundation
import DictionaryCoder

public struct Sponsor: Codable, Hashable, Identifiable {
    public let buttonText: String?
    public let description: String?
    public let id: Int?
    public let imageURL: String?
    public let sponsorPopupHeading: String?
    public let sponsorRedirectUrl: String?

    public static func fromData(data: [String: Any]) throws -> Self {
        try DictionaryDecoder().decode(Self.self, from: data)
    }
}
