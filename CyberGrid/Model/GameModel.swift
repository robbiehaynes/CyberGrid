//
//  GameModel.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

import GameKit

struct GameModel {
    var players: [Player]
    var currentPlayer: Player?
    var grid: Grid
    var winner: String? = nil
    
    init(players: [Player] = [], gridSeed: Int) {
        self.players = players
        self.grid = Grid(seed: gridSeed)
    }
    
    mutating func claimPowerup(at coords: (Int,Int)) {
        grid.nodes[coords.0][coords.1].powerup = nil
    }
    
    mutating func useTurn(for currentPlayer: Player) {
        if let index = players.firstIndex(where: { $0 == currentPlayer }) {
            players[index].movesRemaining -= 1
        }
        
        checkForWinners()
    }
    
    mutating func applyMove(_ move: Move) {
        guard let player = getPlayerByName(move.player) else { return }
        
        grid.applyMove((move.row, move.column), for: player)
        useTurn(for: player)
    }
    
    mutating func checkForWinners() {
        if grid.validMoves(for: players[0]).isEmpty && players[0].movesRemaining > 0 {
            winner = players[1].name
        }
        else if grid.validMoves(for: players[1]).isEmpty && players[1].movesRemaining > 0 {
            winner = players[0].name
        }
        
        if players.allSatisfy({ $0.movesRemaining == 0 }) {
            if let winner = calculateWinner() {
                self.winner = winner.name
            } else {
                self.winner = "draw"
            }
        }
    }
    
    func getPlayerByName(_ name: String) -> Player? {
        return players.first(where: { $0.name == name })
    }
    
    private func calculateWinner() -> Player? {
        var ownershipCount: [Player: Int] = [:]
        
        ownershipCount[players[0]] = grid.nodeCount(for: players[0])
        ownershipCount[players[1]] = grid.nodeCount(for: players[1])
        
        // Check for draw, then find the player with the maximum owned nodes
        if ownershipCount[players[0]]! == ownershipCount[players[1]]! {
            return nil
        }
        
        return ownershipCount.max { $0.value < $1.value }!.key
    }
}
