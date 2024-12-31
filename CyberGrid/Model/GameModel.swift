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
}
