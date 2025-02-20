//
//  GameModelTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//

import XCTest
@testable import CyberGrid

class GameModelTests: XCTestCase {
    var gameModel: GameModel!
    var mockGrid: MockGrid!
    var player1: Player!
    var player2: Player!
    
    override func setUp() {
        super.setUp()
        player1 = Player(name: "Player1", colour: "brand_orange", movesRemaining: 3)
        player2 = Player(name: "Player2", colour: "brand_blue", movesRemaining: 3)
        mockGrid = MockGrid()
        gameModel = GameModel(players: [player1, player2], gridSeed: 42)
    }
    
    override func tearDown() {
        gameModel = nil
        mockGrid = nil
        player1 = nil
        player2 = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertEqual(gameModel.players.count, 2)
        XCTAssertEqual(gameModel.grid.seed, 42)
    }
    
    func testClaimPowerup() {
        gameModel.claimPowerup(at: (0, 0))
        XCTAssertNil(gameModel.grid.nodes[0][0].powerup, "Powerup should be removed from the node")
    }
    
    func testUseTurn() {
        gameModel.useTurn(for: player1)
        XCTAssertEqual(gameModel.players[0].movesRemaining, 2, "Moves remaining should decrease by 1")
    }
    
    func testApplyMove() {
        let move = Move(player: "Player1", coords: (2, 1))
        gameModel.applyMove(move)
        XCTAssertEqual(gameModel.players[0].movesRemaining, 2, "Moves should decrease after applying move")
        XCTAssertEqual(gameModel.grid.nodes[2][1].owner, player1, "Player should own node after applying move")
    }
    
    func testCheckForWinners_NoMovesLeft() {
        gameModel.players[0].movesRemaining = 0
        gameModel.players[1].movesRemaining = 0
        gameModel.checkForWinners()
        XCTAssertEqual(gameModel.winner, "draw", "Game should result in a draw when all moves are used")
    }
    
    func testCheckForWinners_PlayerWins() {
        mockGrid.validMovesResult = []
        gameModel.players[0].movesRemaining = 1
        gameModel.players[1].movesRemaining = 0
        gameModel.checkForWinners()
        XCTAssertEqual(gameModel.winner, "Player2", "Player2 should be the winner")
    }
    
    func testGetPlayerByName() {
        let player = gameModel.getPlayerByName("Player1")
        XCTAssertEqual(player?.name, "Player1")
    }
    
    func testCalculateWinner() {
        gameModel.applyMove(Move(player: player1.name, coords: (2,1)))
        gameModel.players[0].movesRemaining = 0
        gameModel.players[1].movesRemaining = 0
        gameModel.checkForWinners()
        XCTAssertEqual(gameModel.winner, "Player1", "Player1 should win due to higher node count")
    }
}
