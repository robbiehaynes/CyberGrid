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
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(gameModel)
            return data
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    func encode(model: GameModel, outcome: String) -> Data? {
        var model = model
        model.outcome = outcome
        return encode(gameModel: model)
    }
    
    /// Decodes a data representation of match data from another player.
    ///
    /// - Parameter matchData: A data representation of the game data.
    /// - Returns: A game data object.
    func decode(matchData: Data) -> GameModel? {
        // Convert the data object to a game data object.
        return try? PropertyListDecoder().decode(GameModel.self, from: matchData)
    }
}
