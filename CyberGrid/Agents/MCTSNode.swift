//
//  MCTSNode.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/01/2025.
//
import Foundation

import Foundation

class MCTSNode {
    let state: Grid
    let player: Player
    var move: (Int, Int)?
    weak var parent: MCTSNode?

    var wins: Double = 0
    var visits: Double = 0
    var children: [MCTSNode] = []

    init(state: Grid, player: Player, move: (Int, Int)? = nil, parent: MCTSNode? = nil) {
        self.state = state
        self.player = player
        self.move = move
        self.parent = parent
    }

    // ✅ Best child selection using Upper Confidence Bound (UCB1)
    func bestChild(_ exploration: Double) -> MCTSNode {
        return children.max(by: { $0.ucb1(exploration) < $1.ucb1(exploration) })!
    }

    // ✅ UCB1 formula (balances exploration & exploitation)
    func ucb1(_ exploration: Double) -> Double {
        if visits == 0 { return Double.infinity }
        return (wins / visits) + exploration * sqrt(log(parent?.visits ?? 1) / visits)
    }

    // Expand by adding new child nodes for available moves
    func expand() {
        let possibleMoves = state.validMoves(for: player)
        for move in possibleMoves {
            var newState = state.copy()
            newState.applyMove(move, for: player)
            let childNode = MCTSNode(state: newState, player: newState.getOpponent(for: player), move: move, parent: self)
            children.append(childNode)
        }
    }

    // Simulation: Play a semi-random game using a fast evaluation function
    func simulate() -> Double {
        var tempState = state.copy()
        var tempPlayer = player
        
        // Play a full random game until the end
        while !tempState.validMoves(for: tempPlayer).isEmpty {
            let randomMove = tempState.validMoves(for: tempPlayer).randomElement()!
            tempState.applyMove(randomMove, for: tempPlayer)
            tempPlayer.movesRemaining -= 1
            tempPlayer = tempState.getOpponent(for: tempPlayer)
        }
        
        // Determine the winner at the end of the game
        let playerScore = tempState.nodeCount(for: player)
        let opponentScore = tempState.nodeCount(for: tempState.getOpponent(for: player))
        
        if playerScore > opponentScore { return 1 }   // Win
        if playerScore < opponentScore { return -1 }  // Loss
        return 0  // Draw
    }

    // Backpropagation: Update win/loss stats up the tree
    func backpropagate(result: Double) {
        var node: MCTSNode? = self
        while let current = node {
            current.visits += 1
            current.wins += result
            node = current.parent
        }
    }

}

