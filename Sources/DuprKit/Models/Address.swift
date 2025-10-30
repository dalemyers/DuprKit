import Foundation
import DictionaryCoder

public struct Address: Codable, Hashable, Identifiable {
    public let id: Int
    public let addressLine: String?
    public let shortAddress: String?
    public let formattedAddress: String?
    public let latitude: Double?
    public let longitude: Double?
    public let placeId: String?
    public let precision: String?
    public let status: String?
    public let types: String?
    public let create: String?
}
