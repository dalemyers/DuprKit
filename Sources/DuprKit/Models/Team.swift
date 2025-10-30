import Foundation

public struct Team: Codable {
    public let player1: Int
    public let player2: Int?
    public let game1: Int
    public let game2: Int?
    public let game3: Int?
    public let game4: Int?
    public let game5: Int?
    public let winner: Bool
}
