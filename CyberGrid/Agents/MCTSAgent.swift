//
//  MCTSAgent.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/01/2025.
//

import Foundation

class MCTSAgent {
    let maxIterations: Int
    let explorationFactor: Double = 0.9  // 1.414 is a common UCB1 constant

    init(iterations: Int = 1000) {
        self.maxIterations = iterations
    }

    func bestMove(for player: Player, on grid: Grid) -> (Int, Int)? {
        let root = MCTSNode(state: grid, player: player)

        for _ in 0..<maxIterations {
            var node = root

            // 1️⃣ Selection: Traverse the tree using UCB1
            while !node.children.isEmpty {
                node = node.bestChild(explorationFactor)
            }

            // 2️⃣ Expansion: If the node is not terminal, expand it
            if !node.state.validMoves(for: node.player).isEmpty {
                node.expand()
            }

            // 3️⃣ Simulation: Play a random game from one of the new nodes
            let simulationResult = node.simulate()

            // 4️⃣ Backpropagation: Update all parent nodes
            node.backpropagate(result: simulationResult)
        }
        
        for child in root.children {
            print("Move: \(child.move ?? (-1, -1)) Visits: \(child.visits) Wins: \(child.wins) UCB1: \(child.ucb1(0.9))")
        }

        let best = root.bestChild(0)
        print("Best Move: \(best.move ?? (-1, -1)) Visits: \(best.visits) Wins: \(best.wins) UCB1: \(best.ucb1(0.9))")
        return root.bestChild(0).move  // Choose move with highest win rate
    }
}
