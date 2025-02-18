//
//  Leaderboard.swift
//  CyberGrid
//
//  Created by Robert Haynes on 12/02/2025.
//

import GameKit

final class LeaderboardManager {
    
    static let shared = LeaderboardManager()
    var opponentElo: Int?
    
    func onlineGameCompleted(didWin: Bool) {
        guard let opponentElo else { return }
        
        let userElo = self.calculateElo(against: opponentElo, didWin)
        self.setElo(userElo)
    }
    
    func localGameCompleted(withDifficulty difficulty: Int, didWin: Bool) {
        if !didWin { return }
        let score = calculateScore(didWin: didWin)
        
        updateSPScore(by: score)
    }
    
    private func calculateScore(didWin: Bool) -> Int {
        guard didWin else { return 0 }
        
        let difficulty = UserDefaults.standard.integer(forKey: "aiDifficulty")
        let gameLength = UserDefaults.standard.integer(forKey: "numOfMoves")
        let playsFirst = !UserDefaults.standard.bool(forKey: "aiFirst")
        
        // Base points per difficulty
        let basePoints: Int
        switch difficulty {
        case 0:
            basePoints = 100
        case 1:
            basePoints = 250
        default:
            basePoints = 500
        }

        // Adjust for game length
        let lengthMultiplier = 1.0 + (Double(gameLength - 4) * 0.1)
        
        // Playing second gives a slight bonus
        let turnMultiplier = playsFirst ? 1.0 : 1.2
        
        // Final score calculation
        let finalScore = Double(basePoints) * lengthMultiplier * turnMultiplier
        return Int(finalScore.rounded())
    }

    
    private func calculateElo(against opponentElo: Int, _ didWin: Bool) -> Int {
        let userElo = UserDefaults.standard.integer(forKey: "multiplayerElo")
        let K: Double = 32
        
        let expectedScore = 1 / (1 + pow(10, Double(opponentElo - userElo) / 400))
        
        let actualScore: Double = didWin ? 1.0 : 0.0
        
        let newElo = Double(userElo) + K * (actualScore - expectedScore)
        
        return Int(newElo)
    }
    
    func getElo() -> Int {
        return UserDefaults.standard.integer(forKey: "multiplayerElo")
    }
    
    func setElo(_ elo: Int) {
        UserDefaults.standard.set(elo, forKey: "multiplayerElo")
        
        GKLeaderboard.submitScore(elo, context: 0, player: GKLocalPlayer.local, leaderboardIDs: ["CyberGrid.haynoway.MultiplayerElo"]) { error in
            if error != nil {
                print("Error: \(error!.localizedDescription).")
            }
        }
    }
    
    func getSPScore() -> Int {
        return UserDefaults.standard.integer(forKey: "singlePlayerScore")
    }
    
    private func updateSPScore(by score: Int) {
        var currentScore = UserDefaults.standard.integer(forKey: "singlePlayerScore")
        currentScore += score
        
        UserDefaults.standard.set(currentScore, forKey: "singlePlayerScore")
        
        GKLeaderboard.submitScore(currentScore, context: 0, player: GKLocalPlayer.local, leaderboardIDs: ["CyberGrid.haynoway.SinglePlayerScores"]) { error in
            if error != nil {
                print("Error: \(error!.localizedDescription).")
            }
        }
    }
}


extension Task where Failure == Error {
    /// Performs an async task in a sync context.
    ///
    /// - Note: This function blocks the thread until the given operation is finished. The caller is responsible for managing multithreading.
    static func synchronous(priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Success) {
        let semaphore = DispatchSemaphore(value: 0)

        Task(priority: priority) {
            defer { semaphore.signal() }
            return try await operation()
        }

        semaphore.wait()
    }
}
