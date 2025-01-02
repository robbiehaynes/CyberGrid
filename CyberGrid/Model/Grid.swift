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
    
    mutating func initialSetup(players: [Player]) {
        self.nodes[2][2].updateOwner(to: players[1])
        self.nodes[2][3].updateOwner(to: players[0])
        self.nodes[3][2].updateOwner(to: players[0])
        self.nodes[3][3].updateOwner(to: players[1])
    }
    
    func validMoves(for currentPlayer: Player) -> [(Int,Int)] {
        var validMoves: [(Int, Int)] = []
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
                // Skip if the node is already occupied
                if nodes[row][col].owner != nil {
                    continue
                }
                
                // Check each direction for valid outflank
                for direction in directions {
                    var currentRow = row + direction.0
                    var currentCol = col + direction.1
                    var foundOpponent = false
                    
                    // Traverse in the direction
                    while isValidPosition(row: currentRow, col: currentCol),
                          let owner = nodes[currentRow][currentCol].owner,
                          owner != currentPlayer {
                        foundOpponent = true
                        currentRow += direction.0
                        currentCol += direction.1
                    }
                    
                    // If we found an opponent and ended with a currentPlayer node
                    if foundOpponent,
                       isValidPosition(row: currentRow, col: currentCol),
                       nodes[currentRow][currentCol].owner == currentPlayer {
                        validMoves.append((row, col))
                        break // No need to check other directions for this node
                    }
                }
            }
        }
        
        return validMoves
    }
    
    mutating func recalculateOwners(fromCoords coords: (Int,Int)) {
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
        
        let row = coords.0
        let col = coords.1
        
        guard let currentOwner = nodes[row][col].owner else { return }
        
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
    
    private func isValidPosition(row: Int, col: Int) -> Bool {
        return row >= 0 && row < 6 && col >= 0 && col < 6
    }
    
    private func generateNodes() -> [[Node]] {
        // Return an 6x6 2D array of nodes
        let nodes: [[Node]] = Array(repeating: Array(repeating: Node(owner: nil, health: 0), count: 6), count: 6)
        return nodes
    }
}
