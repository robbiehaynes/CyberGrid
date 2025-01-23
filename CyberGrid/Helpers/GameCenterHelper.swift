//
//  GameCenterHelper.swift
//  Rummikub
//
//  Created by Robert Haynes on 2024/11/20.
//

import GameKit

final class GameCenterHelper: NSObject {
    typealias CompletionBlock = (Error?) -> Void
    
    static let helper = GameCenterHelper()
    static var isAuthenticated: Bool {
        return GKLocalPlayer.local.isAuthenticated
    }
    
    var currentMatchmakerVC: GKTurnBasedMatchmakerViewController?
    var viewController: UIViewController?
    var localImage: UIImage = UIImage(systemName: "person.circle.fill")!
    var currentMatch: GKTurnBasedMatch?

    var localAlias: String? {
        GKLocalPlayer.local.alias
    }
    
    var canTakeTurnForCurrentMatch: Bool {
        guard let match = currentMatch else { return true }
        
        return match.isLocalPlayersTurn
    }
    
    enum GameCenterHelperError: Error {
        case matchNotFound
        case gameEncodingError
    }
    
    override init() {
        super.init()
        
        GKLocalPlayer.local.authenticateHandler = { gcAuthVC, error in
            
            NotificationCenter.default.post(
                name: .authenticationChanged,
                object: (GKLocalPlayer.local.isAuthenticated && !GKLocalPlayer.local.isMultiplayerGamingRestricted))
            
            if GKLocalPlayer.local.isAuthenticated {
                GKLocalPlayer.local.register(self)
                GKLocalPlayer.local.loadPhoto(for: .normal) { image, error in
                    if let image = image {
                        self.localImage = image
                    }
                }
            } else if let vc = gcAuthVC {
                self.viewController?.present(vc, animated: true)
            }
            else {
                let alert = UIAlertController(
                    title: "Oh no!",
                    message: "There was an error authenticating your GameCenter credentials. Please try again.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.viewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func presentMatchmaker() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        
        request.inviteMessage = "Would you like to play CyberGrid?"
        
        let vc = GKTurnBasedMatchmakerViewController(matchRequest: request)
        vc.turnBasedMatchmakerDelegate = self
        currentMatchmakerVC = vc
        viewController?.present(vc, animated: true)
    }
    
    func endTurn(_ model: GameModel, completion: @escaping CompletionBlock) {
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }
        
        do {
            match.endTurn(
                withNextParticipants: match.others,
                turnTimeout: GKTurnTimeoutDefault,
                match: try PropertyListEncoder().encode(model),
                completionHandler: completion)
        } catch {
            completion(error)
        }
    }
    
    func win(completion: @escaping CompletionBlock) {
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }
        
        match.currentParticipant?.matchOutcome = .won
        match.others.forEach { other in
            other.matchOutcome = .lost
        }
        
        match.endMatchInTurn(
            withMatch: match.matchData ?? Data(),
            completionHandler: completion
        )
    }
    
    func forfeitMatch(_ model: GameModel, completion: @escaping CompletionBlock) async {
        guard let match = currentMatch else {
            completion(GameCenterHelperError.matchNotFound)
            return
        }
        
        do {
            if canTakeTurnForCurrentMatch {
                // Remove the participants who quit and the current participant.
                let nextParticipants = match.participants.filter {
                  ($0.status != .done) && ($0 != match.currentParticipant)
                }

                // Forfeit the match.
                match.participantQuitInTurn(
                    with: GKTurnBasedMatch.Outcome.quit,
                    nextParticipants: nextParticipants,
                    turnTimeout: GKTurnTimeoutDefault,
                    match: try PropertyListEncoder().encode(model),
                    completionHandler: completion)
            } else {
                try await match.participantQuitOutOfTurn(with: GKTurnBasedMatch.Outcome.quit)
            }
        } catch {
            completion(error)
        }
    }
    
    func getOpponentAlias() -> String? {
        return currentMatch?.others.first?.player!.alias
    }
    
    func getOpponentImage() -> UIImage? {
        var returnImage: UIImage? = nil
        currentMatch?.others.first?.player!.loadPhoto(for: .normal) { image, error in
            if let error = error { return }
            if let image = image { returnImage = image }
        }
        return returnImage
    }
}

extension GameCenterHelper: GKTurnBasedEventListener {
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        GameCenterHelper.helper.currentMatch = nil
    }
}

extension GameCenterHelper: GKTurnBasedMatchmakerViewControllerDelegate {
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFind match: GKTurnBasedMatch) {
        print("Dismissing TBMVC")
    }
    
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        print("Matchmaker vc did fail with error: \(error.localizedDescription).")
    }
}

extension GameCenterHelper: GKLocalPlayerListener {
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        // Remove the current participant. If the count drops below the minimum, the next participant ends the match.
        let nextParticipants = match.participants.filter { $0 != match.currentParticipant }
        
        // Quit while it's the local player's turn.
        match.participantQuitInTurn(with: GKTurnBasedMatch.Outcome.quit, nextParticipants: nextParticipants,
                                    turnTimeout: GKTurnTimeoutDefault, match: match.matchData!)
    }
    
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        
        if currentMatchmakerVC != nil {
            currentMatchmakerVC = nil
            viewController?.presentedViewController?.dismiss(animated: true)
        }

        guard didBecomeActive else { return }
        
        NotificationCenter.default.post(name: .presentGame, object: match)
    }
}



extension Notification.Name {
    static let presentGame = Notification.Name(rawValue: "presentGame")
    static let authenticationChanged = Notification.Name(rawValue: "authenticationChanged")
}
