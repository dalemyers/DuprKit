import Foundation
import DictionaryCoder

public struct Club: Codable, Hashable, Identifiable {
    public let id: Int
    public let name: String
    public let address: Address?
    public let shortAddress: String?
    public let type: ClubType?
    public let iconUrl: String?
    public let memberCount: Int?
    // public let manifest: Any?
    // public let shortDescription: Any?
    // public let longDescription: Any?
    // public let attributes: Any?
    public let role: Role?
    public let isPaymentSetup: Bool?
    public let accountStatus: AccountStatus?
    public let modelType: ModelType?
    public let modelValue: Double?
    public let currencyDetails: CurrencyDetails?
    public let createdDate: String?
    public let requestedBy: Int?
    public let clubJoinType: ClubJoinType?
    public let pendingRequestList: [Int]?
    public let distanceInMiles: Double?

    enum CodingKeys: String, CodingKey {
        case id = "clubId"
        case name = "clubName"
        case type = "clubType"
        case iconUrl = "mediaUrl"
        case address
        case shortAddress
        case memberCount = "clubMemberCount"
        // case manifest
        // case shortDescription
        // case longDescription
        // case attributes
        case role
        case isPaymentSetup
        case accountStatus
        case modelType
        case modelValue
        case currencyDetails
        case createdDate = "created"
        case requestedBy
        case clubJoinType
        case pendingRequestList
        case distanceInMiles
    }

    public var displayLocation: String {
        "Foo"
    }
    
    public static func fromData(data: [String: Any]) throws -> Club {
        return try DictionaryDecoder().decode(Club.self, from: data)
    }
}
