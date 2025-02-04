//
//  MiniAgent.swift
//  CyberGrid
//
//  Created by Robert Haynes on 30/01/2025.
//

import Foundation

class MiniAgent {
    let maxDepth: Int
    var transpositionTable: [Int: Double] = [:]
    
    init(depth: Int = 3) {
        self.maxDepth = depth
    }
    
    func bestMove(for player: Player, on grid: Grid) -> (Int, Int)? {
        var bestScore = -Double.infinity
        var bestMove: (Int, Int)? = nil
        
        var possibleMoves = grid.validMoves(for: player)
        
        // Sort moves to prioritise better positions
        possibleMoves.sort { move1, move2 in
            var grid1 = grid.copy()
            grid1.applyMove(move1, for: player)
            let score1 = evaluate(grid: grid1, for: player)
            
            var grid2 = grid.copy()
            grid2.applyMove(move2, for: player)
            let score2 = evaluate(grid: grid2, for: player)
            
            return score1 > score2
        }
        
        for move in possibleMoves {
            var simulatedGrid = grid.copy()
            simulatedGrid.applyMove(move, for: player)
            
            var simulatedPlayer = player
            simulatedPlayer.movesRemaining -= 1
            
            let score = minimax(grid: simulatedGrid, depth: maxDepth, maximising: false, player: simulatedPlayer, alpha: -Double.infinity, beta: Double.infinity)
            
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    private func minimax(grid: Grid, depth: Int, maximising: Bool, player: Player, alpha: Double, beta: Double) -> Double {
        var alpha = alpha
        var beta = beta
        let boardHash = grid.boardHash()
        
        // Check if we've evaluated this board
        if let cachedScore = transpositionTable[boardHash] {
            return cachedScore
        }
        
        // Stop if AI has no moves or we reached max depth
        if depth == 0 || (maximising && grid.validMoves(for: player).isEmpty) {
            let score = evaluate(grid: grid, for: player)
            transpositionTable[boardHash] = score
            return score
        }
        
        let opponent = grid.getOpponent(for: player)
        let possibleMoves = grid.validMoves(for: maximising ? player : opponent)
        
        // Stop if opponent also has no moves (game is over)
        if possibleMoves.isEmpty {
            return evaluate(grid: grid, for: player)
        }
        
        var bestScore = maximising ? -Double.infinity : Double.infinity
        
        for move in possibleMoves {
            var simulatedGrid = grid.copy()
            simulatedGrid.applyMove(move, for: maximising ? player : opponent)
            
            var simulatedPlayer = player
            if maximising { simulatedPlayer.movesRemaining -= 1 }
            
            let score = minimax(grid: simulatedGrid, depth: depth-1, maximising: !maximising, player: simulatedPlayer, alpha: alpha, beta: beta)
            
            if maximising {
                bestScore = max(bestScore, score)
                alpha = max(alpha, score)
            } else {
                bestScore = min(bestScore, score)
                beta = min(beta, score)
            }
            
            if beta <= alpha { break }
        }
        
        transpositionTable[boardHash] = bestScore
        return bestScore
    }
    
    private func evaluate(grid: Grid, for player: Player) -> Double {
        let opponent = grid.getOpponent(for: player)
        let playerNodes = grid.nodeCount(for: player)
        let opponentNodes = grid.nodeCount(for: opponent)
        
        let playerMoves = grid.validMoves(for: player).count
        let opponentMoves = grid.validMoves(for: opponent).count
        
        // Avoid division by zero
        let totalDiscs = playerNodes + opponentNodes
        let totalMoves = playerMoves + opponentMoves
        
        let discDiff: Double = totalDiscs > 0 ? Double(playerNodes - opponentNodes) / Double(totalDiscs) : 0.0
        let mobility: Double = totalMoves > 0 ? Double(playerMoves - opponentMoves) / Double(totalMoves) : 0.0
        
        // Compute final game value with equal weights
        return 0.5 * discDiff + 0.5 * mobility
    }

    
}
