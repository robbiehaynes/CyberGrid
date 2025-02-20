//
//  SeededGeneratorTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//

import XCTest
@testable import CyberGrid

class SeededGeneratorTests: XCTestCase {
    func testDeterministicOutput() {
        var generator1 = SeededGenerator(seed: 42)
        var generator2 = SeededGenerator(seed: 42)
        XCTAssertEqual(generator1.next(), generator2.next(), "Generators with the same seed should produce the same output.")
    }
    
    func testDifferentSeedsProduceDifferentOutputs() {
        var generator1 = SeededGenerator(seed: 42)
        var generator2 = SeededGenerator(seed: 43)
        XCTAssertNotEqual(generator1.next(), generator2.next(), "Different seeds should produce different outputs.")
    }
    
    func testDeterministicNumberGeneration() {
        var generatorOne = SeededGenerator(seed: 42)
        var generatorTwo = SeededGenerator(seed: 42)
        
        let intOne = Int.random(in: 0...999, using: &generatorOne)
        let intTwo = Int.random(in: 0...999, using: &generatorTwo)
        
        XCTAssertEqual(intOne, intTwo, "Same seed should produce the same sequence of random numbers.")
    }
}

class GridSeedGeneratorTests: XCTestCase {
    func testSamePlayersGenerateSameSeed() {
        let seed1 = GridSeedGenerator.shared.generateSeed(player1ID: "Alice", player2ID: "Bob")
        let seed2 = GridSeedGenerator.shared.generateSeed(player1ID: "Alice", player2ID: "Bob")
        XCTAssertEqual(seed1, seed2, "Same player IDs should produce the same seed.")
    }
    
    func testDifferentPlayersGenerateDifferentSeeds() {
        let seed1 = GridSeedGenerator.shared.generateSeed(player1ID: "Alice", player2ID: "Bob")
        let seed2 = GridSeedGenerator.shared.generateSeed(player1ID: "Charlie", player2ID: "Dave")
        XCTAssertNotEqual(seed1, seed2, "Different player IDs should produce different seeds.")
    }
    
    func testStableSeedOverTime() {
        let seed1 = GridSeedGenerator.shared.generateSeed(player1ID: "Alice", player2ID: "Bob", timestamp: 100000)
        let seed2 = GridSeedGenerator.shared.generateSeed(player1ID: "Alice", player2ID: "Bob", timestamp: 100001)
        XCTAssertNotEqual(seed1, seed2, "Seed should change over time due to timestamp influence.")
    }
}
