//
//  Node.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

struct Pair: Hashable {
    let first: Int
    let second: Int
}

struct Grid: Codable {
    var nodes: [[Node]] = []
    
    init(nodes: [[Node]] = []) {
        if nodes.isEmpty {
            self.nodes = generateNodes()
        } else {
            self.nodes = nodes
        }
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
        
        if currentPlayer.movesRemaining == 0 {
            return validMoves
        }
        
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
    
    func copy() -> Grid {
        var newNodes: [[Node]] = []
        
        for row in nodes {
            var newRow: [Node] = []
            for node in row {
                newRow.append(node)
            }
            newNodes.append(newRow)
        }
        
        return Grid(nodes: newNodes)
    }
    
    func getOpponent(for player: Player) -> Player {
        for row in 0..<6 {
            for col in 0..<6 {
                if nodes[row][col].owner != player && nodes[row][col].owner != nil {
                    return nodes[row][col].owner!
                }
            }
        }
        return player
    }
    
    func nodeCount(for player: Player) -> Int {
        // Return the number of nodes owned by player
        return nodes.flatMap { $0 }.filter { $0.owner == player }.count
    }
    
    func applyingMove(_ move: (Int, Int), for player: Player) -> Grid {
        var newGrid = self.copy()
        newGrid.applyMove(move, for: player)
        return newGrid
    }
    
    mutating func applyMove(_ move: (Int, Int), for player: Player) {
        let (row, col) = move
        nodes[row][col].attack(player: player)
        recalculateOwners(fromCoords: move)
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
            var maxOppHealth = -1
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
    
    mutating func reassignPowerups(locations: [Pair]) {
        removePowerups()
        let powerUps: [Powerup] = [.firewall, .firewall, .firewall, .firewall]
        
        for (index, pair) in locations.enumerated() {
            nodes[pair.first][pair.second].powerup = powerUps[index]
        }
    }
    
    func getPowerupLocations() -> [Pair] {
        var locations: [Pair] = []
        
        for i in 0..<6 {
            for j in 0..<6 {
                if let _ = nodes[i][j].powerup {
                    locations.append(Pair(first: i, second: j))
                }
            }
        }
        
        return locations
    }
    
    private mutating func removePowerups() {
        for i in 0..<6 {
            for j in 0..<6 {
                nodes[i][j].powerup = nil
            }
        }
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

extension Grid: Equatable {
    static func == (lhs: Grid, rhs: Grid) -> Bool {
        return lhs.nodes == rhs.nodes
    }
}

extension Grid: Hashable {
    func hash(into hasher: inout Hasher) {
        for row in nodes {
            for node in row {
                hasher.combine(node)
            }
        }
    }
    
    func boardHash() -> Int {
        var hasher = Hasher()
        for row in nodes {
            for node in row {
                hasher.combine(node.colour)
                hasher.combine(node.health)
            }
        }
        return hasher.finalize()
    }
}
