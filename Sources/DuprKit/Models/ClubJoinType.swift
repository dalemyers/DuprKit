import Foundation

public enum ClubJoinType: String, Codable {
    case invitation = "INVITATION"
    case request = "REQUEST"
    case invitationCsv = "INVITATION_CSV"
    case partnerInvite = "PARTNER_INVITE"
}
