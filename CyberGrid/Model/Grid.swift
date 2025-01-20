//
//  Node.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

enum Powerup: Codable {
    case firewall
}

struct Node: Codable {
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

struct Pair: Hashable {
    let first: Int
    let second: Int
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
    
    func validMoves(for currentPlayer: Player, _ fortifying: Bool = false) -> [(Int,Int)] {
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
                if fortifying {
                    if nodes[row][col].owner == currentPlayer {
                        validMoves.append((row, col))
                    }
                    continue
                }
                
                if nodes[row][col].owner != nil {
                    continue
                }
                
                // Check each direction for valid outflank
                for direction in directions {
                    var currentRow = row + direction.0
                    var currentCol = col + direction.1
                    var foundOpponent = false
                    var maxOppHealth = -1
                    
                    // Traverse in the direction
                    while isValidPosition(row: currentRow, col: currentCol),
                          let owner = nodes[currentRow][currentCol].owner,
                          owner != currentPlayer {
                        foundOpponent = true
                        maxOppHealth = max(maxOppHealth, nodes[currentRow][currentCol].health)
                        currentRow += direction.0
                        currentCol += direction.1
                    }
                    
                    // If we found an opponent and ended with a currentPlayer node
                    if foundOpponent,
                       isValidPosition(row: currentRow, col: currentCol),
                       nodes[currentRow][currentCol].owner == currentPlayer {
                        if nodes[currentRow][currentCol].health >= maxOppHealth {
                            validMoves.append((row, col))
                            break // No need to check other directions for this node
                        }
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
        var maxOppHealth = -1
        
        guard let currentOwner = nodes[row][col].owner else { return }
        
        for direction in directions {
            var path = [(row, col)]
            var currentRow = row + direction.0
            var currentCol = col + direction.1
            
            while isValidPosition(row: currentRow, col: currentCol),
                  let nextOwner = nodes[currentRow][currentCol].owner,
                  nextOwner != currentOwner {
                path.append((currentRow, currentCol))
                maxOppHealth = max(maxOppHealth, nodes[currentRow][currentCol].health)
                currentRow += direction.0
                currentCol += direction.1
            }
            
            if isValidPosition(row: currentRow, col: currentCol),
                nodes[currentRow][currentCol].owner == currentOwner,
                max(nodes[row][col].health, nodes[currentRow][currentCol].health) >= maxOppHealth {
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
        var nodes: [[Node]] = Array(repeating: Array(repeating: Node(owner: nil, health: 0), count: 6), count: 6)
        
        nodes = assignRandomPowerups(toNodes: nodes)
        
        return nodes
    }
    
    private func assignRandomPowerups(toNodes nodes: [[Node]]) -> [[Node]] {
        var updatedNodes = nodes
        let uniquePairs = generateUniquePairs(count: 4)
        let powerUps: [Powerup] = [.firewall, .firewall, .firewall, .firewall]
        
        for (index, pair) in uniquePairs.enumerated() {
            let row = pair.first
            let col = pair.second
            
            // Assign the power-up corresponding to the index
            updatedNodes[row][col].powerup = powerUps[index]
        }
        
        return updatedNodes
    }
    
    private func generateUniquePairs(count: Int) -> [Pair] {
        let excludedPairs: Set<Pair> = [
            Pair(first: 2, second: 2),
            Pair(first: 2, second: 3),
            Pair(first: 3, second: 2),
            Pair(first: 3, second: 3)
        ]
        
        var generatedPairs: Set<Pair> = []
        
        while generatedPairs.count < count {
            let first = Int.random(in: 0...5)
            let second = Int.random(in: 0...5)
            let pair = Pair(first: first, second: second)
            
            if !excludedPairs.contains(pair) && !generatedPairs.contains(pair) {
                generatedPairs.insert(pair)
            }
        }
        
        return Array(generatedPairs)
    }
}
