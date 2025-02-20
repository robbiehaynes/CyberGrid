//
//  PlayerTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//
import XCTest
@testable import CyberGrid

class PlayerTests: XCTestCase {
    var player1: Player!
    var player2: Player!
    var localPlayer: Player!
    
    override func setUp() {
        super.setUp()
        let image = UIImage(systemName: "person")!
        player1 = Player(name: "Alice", colour: "Red", movesRemaining: 3, profileImage: image)
        player2 = Player(name: "Bob", colour: "Blue", movesRemaining: 2, profileImage: image)
        localPlayer = Player(name: "LocalUser", colour: "Green", movesRemaining: 5, profileImage: image)
    }
    
    override func tearDown() {
        player1 = nil
        player2 = nil
        localPlayer = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertEqual(player1.name, "Alice")
        XCTAssertEqual(player1.colour, "Red")
        XCTAssertEqual(player1.movesRemaining, 3)
        XCTAssertNotNil(player1.profileImage)
    }
    
    func testEquatable() {
        let duplicatePlayer = Player(name: "Alice", colour: "Red", movesRemaining: 3, profileImage: UIImage(systemName: "person.fill")!)
        XCTAssertEqual(player1, duplicatePlayer, "Players with the same name and color should be equal.")
        XCTAssertNotEqual(player1, player2, "Different players should not be equal.")
    }
    
    func testHashable() {
        var playerSet: Set<Player> = []
        playerSet.insert(player1)
        playerSet.insert(player2)
        XCTAssertEqual(playerSet.count, 2, "Player set should contain unique players.")
    }
}

class MoveTests: XCTestCase {
    func testMoveInitialization() {
        let move = Move(player: "Alice", coords: (2, 3))
        XCTAssertEqual(move.player, "Alice")
        XCTAssertEqual(move.row, 2)
        XCTAssertEqual(move.column, 3)
    }
    
    func testMoveEncodingDecoding() {
        let move = Move(player: "Alice", coords: (1, 4))
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(move)
            let decodedMove = try decoder.decode(Move.self, from: data)
            XCTAssertEqual(decodedMove, move, "Decoded move should be identical to the original move")
        } catch {
            XCTFail("Encoding or decoding failed: \(error)")
        }
    }
}
