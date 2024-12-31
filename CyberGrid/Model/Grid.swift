//
//  Node.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

struct Node: Codable {
    let owner: Player?
    let health: Int
    var colour: String {
        if owner == nil {
            return "green"
        } else {
            return owner!.colour
        }
    }
}

struct Grid: Codable {
    var nodes: [[Node]] = []
    
    init() {
        self.nodes = generateNodes()
    }
    
    func getNode(atRow: Int, atCol: Int) -> Node? {
        if atRow < 8 && atCol < 8 {
            return nodes[atRow][atCol]
        } else {
            return nil
        }
    }
    
    private func generateNodes() -> [[Node]] {
        // Return an 8x8 2D array of nodes
        let nodes: [[Node]] = Array(repeating: Array(repeating: Node(owner: nil, health: 0), count: 8), count: 8)
        return nodes
    }
}
