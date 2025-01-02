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
    
    mutating func updateOwner(to newOwner: Player?) {
        self.owner = newOwner
        self.health = 1
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
    
    mutating func recalculateOwners() {
        let directions = [
            (0, 1),  // Right
            (1, 0),  // Down
            (0, -1), // Left
            (-1, 0), // Up
            (1, 1),  // Down-right
            (1, -1), // Down-left
            (-1, 1), // Up-right
            (-1, -1) // Up-left
        ]
        
        for row in 0..<nodes.count {
            for col in 0..<nodes[row].count {
                guard let currentOwner = nodes[row][col].owner else { continue }
                
                for direction in directions {
                    var path = [(row, col)]
                    var currentRow = row + direction.0
                    var currentCol = col + direction.1
                    
                    while isValidPosition(row: currentRow, col: currentCol),
                            let nextOwner = nodes[currentRow][currentCol].owner,
                            nextOwner != currentOwner {
                        path.append((currentRow, currentCol))
                        currentRow += direction.0
                        currentCol += direction.1
                    }
                    
                    if isValidPosition(row: currentRow, col: currentCol),
                       nodes[currentRow][currentCol].owner == currentOwner {
                        // Flip all nodes in the path
                        for (flipRow, flipCol) in path.dropFirst() {
                            nodes[flipRow][flipCol].updateOwner(to: currentOwner)
                        }
                    }
                }
            }
        }
    }
    
    private func isValidPosition(row: Int, col: Int) -> Bool {
        return row >= 0 && row < 6 && col >= 0 && col < 6
    }
    
    private func generateNodes() -> [[Node]] {
        // Return an 6x6 2D array of nodes
        let nodes: [[Node]] = Array(repeating: Array(repeating: Node(owner: nil, health: 0), count: 6), count: 6)
        return nodes
    }
}
