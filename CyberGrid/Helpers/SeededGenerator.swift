//
//  SeededGenerator.swift
//  CyberGrid
//
//  Created by Robert Haynes on 12/02/2025.
//
import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(seed)
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}

struct GridSeedGenerator {
    static let shared = GridSeedGenerator()
    
    private init() {}
    
    func generateSeed(player1ID: String, player2ID: String) -> Int {
        let sortedIDs = [player1ID, player2ID].sorted().joined()  // Ensure order consistency
        let minuteTimestamp = Int(Date().timeIntervalSince1970) / 60  // Round to the minute
        return (sortedIDs.hashValue ^ minuteTimestamp) & 0x7FFFFFFF  // Ensure positive seed
    }
}
