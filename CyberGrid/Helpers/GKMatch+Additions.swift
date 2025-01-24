//
//  GKTurnBasedMatch+Additions.swift
//  Rummikub
//
//  Created by Robert Haynes on 2024/11/22.
//

import GameKit

extension GKMatch {
    var others: [GKPlayer] {
        return players.filter {
            return $0 != GKLocalPlayer.local
        }
    }
}
