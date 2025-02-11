//
//  GameModel+Data.swift
//  CyberGrid
//
//  Created by Robert Haynes on 24/01/2025.
//
import Foundation
import GameKit

extension GameCenterHelper {
    func encode(gameModel: GameModel) -> Data? {
        do {
            return try JSONEncoder().encode(gameModel)
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    /// Decodes a data representation of match data from another player.
    ///
    /// - Parameter matchData: A data representation of the game data.
    /// - Returns: A game data object.
    func decode(matchData: Data) -> GameModel? {
        // Convert the data object to a game data object.
        return try? JSONDecoder().decode(GameModel.self, from: matchData)
    }
}
