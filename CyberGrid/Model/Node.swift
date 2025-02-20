//
//  Node.swift
//  CyberGrid
//
//  Created by Robert Haynes on 30/01/2025.
//

enum Powerup: Codable {
    case firewall
}

struct Node {
    var owner: Player?
    var health: Int
    var powerup: Powerup?
    var colour: String {
        if owner == nil {
            return "white"
        } else {
            return owner!.colour
        }
    }
    
    mutating func fortify() {
        health += 1
    }
    
    mutating func attack(player: Player) {
        health -= 1
        
        if health <= 0 {
            owner = player
            if self.powerup == .firewall {
                health = 2
            } else {
                health = 1
            }
        }
    }
    
    mutating func updateOwner(to newOwner: Player?) {
        self.owner = newOwner
        self.health = 1
    }
}

extension Node: Equatable {
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.owner == rhs.owner &&
        lhs.health == rhs.health &&
        lhs.powerup == rhs.powerup
    }
}

extension Node: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(owner)
        hasher.combine(health)
        hasher.combine(powerup)
    }
}
