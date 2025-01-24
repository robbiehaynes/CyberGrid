//
//  GameModel.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

import GameKit

struct GameModel: Codable {
    var players: [Player]
    var grid: Grid
    var winner: String? = nil
    var outcome: String? = nil
    
    init(players: [Player] = [], grid: Grid = Grid()) {
        self.players = players
        self.grid = grid
    }
    
    mutating func claimPowerup(at coords: (Int,Int)) {
        grid.nodes[coords.0][coords.1].powerup = nil
    }
    
    mutating func useTurn(for currentPlayer: Player) {
        if let player = players.first(where: { $0 == currentPlayer }), player.movesRemaining > 0 {
            player.movesRemaining -= 1
        }
        
        if players.allSatisfy({ $0.movesRemaining == 0 }) {
            winner = calculateWinner().name
        }
    }
    
    private func calculateWinner() -> Player {
        var ownershipCount: [Player: Int] = [:]

        for row in grid.nodes {
            for node in row {
                if let owner = node.owner {
                    ownershipCount[owner, default: 0] += 1
                }
            }
        }
        
        // Find the player with the maximum owned nodes
        return ownershipCount.max { $0.value < $1.value }!.key
    }
}
