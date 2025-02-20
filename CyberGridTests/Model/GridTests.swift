//
//  GridTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//

import XCTest
@testable import CyberGrid

class GridTests: XCTestCase {
    var grid: Grid!
    var player1: Player!
    var player2: Player!
    
    override func setUp() {
        super.setUp()
        let image = UIImage(systemName: "person.fill")!
        player1 = Player(name: "Alice", colour: "Red", movesRemaining: 3, profileImage: image)
        player2 = Player(name: "Bob", colour: "Blue", movesRemaining: 2, profileImage: image)
        grid = Grid(seed: 42)
    }
    
    override func tearDown() {
        grid = nil
        player1 = nil
        player2 = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertEqual(grid.seed, 42)
        XCTAssertEqual(grid.nodes.count, 6)
        XCTAssertEqual(grid.nodes[0].count, 6)
    }
    
    func testInitialSetup() {
        grid.initialSetup(players: [player1, player2])
        XCTAssertEqual(grid.nodes[2][2].owner, player2)
        XCTAssertEqual(grid.nodes[2][3].owner, player1)
        XCTAssertEqual(grid.nodes[3][2].owner, player1)
        XCTAssertEqual(grid.nodes[3][3].owner, player2)
    }
    
    func testValidMoves() {
        grid.initialSetup(players: [player1, player2])
        let moves = grid.validMoves(for: player1)
        XCTAssertGreaterThanOrEqual(moves.count, 0, "Valid moves should be calculated correctly.")
    }
    
    func testCopy() {
        let copiedGrid = grid.copy()
        XCTAssertEqual(grid, copiedGrid, "Copied grid should be identical to the original.")
    }
    
    func testApplyMove() {
        grid.initialSetup(players: [player1, player2])
        let move = (4, 4)
        grid.applyMove(move, for: player1)
        XCTAssertEqual(grid.nodes[4][4].owner, player1, "Move should be applied correctly.")
    }
    
    func testApplyingMove() {
        grid.initialSetup(players: [player1, player2])
        let move = (4, 4)
        let newGrid = grid.applyingMove(move, for: player1)
        XCTAssertEqual(newGrid.nodes[4][4].owner, player1, "Applying move should return a correctly updated grid.")
    }
    
    func testNodeCount() {
        grid.initialSetup(players: [player1, player2])
        XCTAssertGreaterThanOrEqual(grid.nodeCount(for: player1), 0)
    }
    
    func testGetOpponent() {
        grid.initialSetup(players: [player1, player2])
        let opponent = grid.getOpponent(for: player1)
        XCTAssertEqual(opponent, player2, "Opponent should be identified correctly.")
    }
    
    func testBoardHash() {
        let hash1 = grid.boardHash()
        let hash2 = grid.copy().boardHash()
        XCTAssertEqual(hash1, hash2, "Board hash should remain consistent for identical grids.")
    }
}


//MARK: - Mock

struct MockGrid: GridProtocol {
    
    var nodes: [[Node]] = Array(repeating: Array(repeating: Node(owner: nil, health: 0), count: 6), count: 6)
    var validMovesResult: [(Int, Int)] = []
    var moveApplied: (Int, Int)?
    var playerNodeCount: [Player: Int] = [:]
    
    func validMoves(for player: Player) -> [(Int, Int)] {
        return validMovesResult
    }
    
    mutating func applyMove(_ move: (Int, Int), for player: Player) {
        moveApplied = move
    }
    
    func nodeCount(for player: Player) -> Int {
        return playerNodeCount[player] ?? 0
    }
}
