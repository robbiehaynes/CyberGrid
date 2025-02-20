//
//  NodeTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//

import XCTest
@testable import CyberGrid

class NodeTests: XCTestCase {
    var player1: Player!
    var player2: Player!
    
    override func setUp() {
        super.setUp()
        let image = UIImage(systemName: "person.fill")!
        player1 = Player(name: "Alice", colour: "Red", movesRemaining: 3, profileImage: image)
        player2 = Player(name: "Bob", colour: "Blue", movesRemaining: 2, profileImage: image)
    }
    
    override func tearDown() {
        player1 = nil
        player2 = nil
        super.tearDown()
    }
    
    func testInitialization() {
        let node = Node(owner: nil, health: 3, powerup: nil)
        XCTAssertNil(node.owner)
        XCTAssertEqual(node.health, 3)
        XCTAssertNil(node.powerup)
        XCTAssertEqual(node.colour, "white")
    }
    
    func testFortify() {
        var node = Node(owner: player1, health: 2, powerup: nil)
        node.fortify()
        XCTAssertEqual(node.health, 3, "Fortify should increase health by 1")
    }
    
    func testAttack_DecreasesHealth() {
        var node = Node(owner: player1, health: 2, powerup: nil)
        node.attack(player: player2)
        XCTAssertEqual(node.health, 1, "Attack should decrease health by 1")
    }
    
    func testAttack_TransfersOwnership_WhenHealthReachesZero() {
        var node = Node(owner: player1, health: 1, powerup: nil)
        node.attack(player: player2)
        XCTAssertEqual(node.owner, player2, "Ownership should transfer when health reaches 0")
        XCTAssertEqual(node.health, 1, "New owner should start with 1 health")
    }
    
    func testAttack_WithFirewallPowerup() {
        var node = Node(owner: player1, health: 1, powerup: .firewall)
        node.attack(player: player2)
        XCTAssertEqual(node.owner, player2, "Ownership should transfer")
        XCTAssertEqual(node.health, 2, "Firewall powerup should set new owner's health to 2")
    }
    
    func testUpdateOwner() {
        var node = Node(owner: player1, health: 5, powerup: nil)
        node.updateOwner(to: player2)
        XCTAssertEqual(node.owner, player2)
        XCTAssertEqual(node.health, 1, "Health should reset to 1 when owner changes")
    }
    
    func testEquatable() {
        let node1 = Node(owner: player1, health: 2, powerup: nil)
        let node2 = Node(owner: player1, health: 2, powerup: nil)
        XCTAssertEqual(node1, node2, "Nodes with the same properties should be equal")
    }
    
    func testHashable() {
        let node1 = Node(owner: player1, health: 2, powerup: nil)
        let node2 = Node(owner: player2, health: 2, powerup: nil)
        var nodeSet: Set<Node> = []
        nodeSet.insert(node1)
        nodeSet.insert(node2)
        XCTAssertEqual(nodeSet.count, 2, "HashSet should contain unique nodes")
    }
}
