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
    
    init(players: [Player], grid: Grid = Grid(), winner: String? = nil) {
        self.players = players
        self.grid = grid
        self.winner = winner
    }
}
