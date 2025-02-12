//
//  Leaderboard.swift
//  CyberGrid
//
//  Created by Robert Haynes on 12/02/2025.
//

import GameKit

enum Difficulty {
    case easy
    case medium
    case hard
}

final class LeaderboardManager {
    
    static let shared = LeaderboardManager()
    
    func onlineGameCompleted(against opponent: GKPlayer, didWin: Bool) {
        Task.synchronous {
            do {
                let leaderboard = try await GKLeaderboard.loadLeaderboards(IDs: ["CyberGrid.haynoway.MultiplayerElo"]).first

                if let leaderboard = leaderboard {
                    let entries = try await leaderboard.loadEntries(for: [opponent], timeScope: .allTime)

                    if let opponentEntry = entries.0 {
                        let opponentElo = opponentEntry.score
                        let userElo = self.calculateElo(against: opponentElo, didWin)
                        self.setElo(userElo)
                    } else {
                        print("No opponent Elo found.")
                    }
                } else {
                    print("Leaderboard not found.")
                }
            } catch {
                print("Error loading leaderboard: \(error.localizedDescription)")
            }
        }
    }
    
    func localGameCompleted(withDifficulty difficulty: Difficulty, didWin: Bool) {
        if !didWin { return }
        
        switch difficulty {
            case .easy:
                updateSPScore(by: 100)
            case .medium:
                updateSPScore(by: 250)
            case .hard:
                updateSPScore(by: 500)
        }
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
