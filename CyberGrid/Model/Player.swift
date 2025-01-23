//
//  Player.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//
import UIKit

class Player : Codable, Equatable, Hashable {
    static func == (lhs: Player, rhs: Player) -> Bool {
        if lhs.colour != rhs.colour { return false }
        if lhs.name != rhs.name { return false }
        if lhs.movesRemaining != rhs.movesRemaining { return false }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    let name: String
    let colour: String
    let profileImage: Data
    var movesRemaining: Int
    
    init(name: String, colour: String, movesRemaining: Int, profileImage: UIImage) {
        self.name = name
        self.colour = colour
        self.movesRemaining = movesRemaining
        self.profileImage = profileImage.data!
    }
}
