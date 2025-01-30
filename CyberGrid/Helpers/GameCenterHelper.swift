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
    
    var currentMatchmakerVC: GKMatchmakerViewController?
    var viewController: UIViewController?
    var localImage: UIImage = UIImage(systemName: "person.circle.fill")!
    var currentMatch: GKMatch?

    var localAlias: String? {
        GKLocalPlayer.local.alias
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
        
        let vc = GKMatchmakerViewController(matchRequest: request)
        vc!.matchmakerDelegate = self
        currentMatchmakerVC = vc
        viewController?.present(vc!, animated: true)
    }
    
    func getOpponentAlias() -> String? {
        return currentMatch?.others.first?.alias
    }
    
    func getOpponentImage() -> UIImage? {
        var returnImage: UIImage? = nil
        currentMatch?.others.first?.loadPhoto(for: .normal) { image, error in
            if error != nil { return }
            if let image = image { returnImage = image }
        }
        return returnImage
    }
    
    func startMatch(match: GKMatch) {
        currentMatch = match
        currentMatch?.delegate = self
        
        var gameModel = GameModel()
        
        gameModel.players = [
            Player(
                name: localAlias ?? "",
                colour: "coral",
                movesRemaining: 6,
                profileImage: localImage),
            Player(
                name: getOpponentAlias() ?? "",
                colour: "coral",
                movesRemaining: 6,
                profileImage: getOpponentImage() ?? UIImage(systemName: "person.circle.fill")!)
        ]
        
        NotificationCenter.default.post(name: .presentGame, object: gameModel)
    }
    
    func sendModel(_ model: GameModel) {
        do {
            let data = encode(gameModel: model)
            try currentMatch?.sendData(toAllPlayers: data!, with: .unreliable)
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
    
    func forfeitMatch(_ model: GameModel) {
        // Notify the opponent that you forfeit the game.
        var localModel = model
        localModel.winner = getOpponentAlias()
        
        do {
            let data = encode(gameModel: model)
            try currentMatch?.sendData(toAllPlayers: data!, with: .unreliable)
            NotificationCenter.default.post(name: .gameEnded, object: getOpponentAlias())
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
}

extension GameCenterHelper: GKTurnBasedEventListener {
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        GameCenterHelper.helper.currentMatch = nil
    }
}

extension GameCenterHelper: GKMatchmakerViewControllerDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        print("Dismissing MVC")
        
        startMatch(match: match)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: any Error) {
        print("Matchmaker vc did fail with error: \(error.localizedDescription).")
    }
}

extension GameCenterHelper: GKLocalPlayerListener {
    
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        // Present the matchmaker view controller in the invitation state.
        if let mmViewController = GKMatchmakerViewController(invite: invite) {
            mmViewController.matchmakerDelegate = self
            viewController?.present(mmViewController, animated: true) { }
        }
    }
    
    func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer]) {
        print("\n\nSending invites to other players.")
    }
}

extension GameCenterHelper: GKMatchDelegate {
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
            case .connected:
                print("\(player.displayName) Connected")
            case .disconnected:
                print("\(player.displayName) Disconnected")
            default:
                print("\(player.displayName) Connection Unknown")
        }
    }
    
    func match(_ match: GKMatch, didFailWithError error: (any Error)?) {
        print("\n\nMatch object fails with error: \(error!.localizedDescription)")
    }
    
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
        return true
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        let gameModel = decode(matchData: data)
        
        NotificationCenter.default.post(name: .gameModelChanged, object: gameModel)
    }
}



extension Notification.Name {
    static let presentGame = Notification.Name(rawValue: "presentGame")
    static let gameModelChanged = Notification.Name(rawValue: "gameModelChanged")
    static let authenticationChanged = Notification.Name(rawValue: "authenticationChanged")
    static let gameEnded = Notification.Name(rawValue: "gameEnded")
}
