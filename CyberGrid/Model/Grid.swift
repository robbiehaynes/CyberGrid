//
//  Node.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

struct Node: Codable {
    var owner: Player?
    var health: Int
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
    
    mutating func attack(withVirus: Bool, player: Player) {
        if withVirus {
            health -= 2
        } else {
            health -= 1
        }
        
        if health <= 0 {
            owner = player
            health = 1
        }
    }
}

struct Grid: Codable {
    var nodes: [[Node]] = []
    
    init() {
        self.nodes = generateNodes()
    }
    
    func getNode(atRow: Int, atCol: Int) -> Node {
        return nodes[atRow][atCol]
    }
    
    private func generateNodes() -> [[Node]] {
        // Return an 6x6 2D array of nodes
        let nodes: [[Node]] = Array(repeating: Array(repeating: Node(owner: nil, health: 0), count: 6), count: 6)
        return nodes
    }
}
