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
    
    var currentOpponent: GKPlayer? {
        currentMatch?.players.first
    }

    var localAlias: String? {
        GameCenterHelper.isAuthenticated ? GKLocalPlayer.local.alias : "You"
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
                
                // Add GKAccessPoint
                GKAccessPoint.shared.location = .topLeading
                GKAccessPoint.shared.showHighlights = true
                
                if UserDefaults.standard.bool(forKey: "onBoardingCompleted") {
                    GKAccessPoint.shared.isActive = true
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
    
    func setAccessPointIsActive(_ state: Bool) {
        GKAccessPoint.shared.isActive = state
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
        return currentOpponent?.alias
    }
    
    func getOpponentImage() -> UIImage? {
        var returnImage: UIImage? = nil
        currentOpponent?.loadPhoto(for: .normal) { image, error in
            if error != nil { return }
            if image != nil { returnImage = image }
        }
        return returnImage
    }
    
    func startMatch(match: GKMatch) {
        currentMatch = match
        currentMatch?.delegate = self

        let uniqueSeed = GridSeedGenerator.shared.generateSeed(player1ID: GKLocalPlayer.local.displayName,
                                                               player2ID: currentMatch!.players.first!.displayName)
        let isPlayer1 = determineFirstPlayer(usingSeed: uniqueSeed, in: match) == GKLocalPlayer.local.displayName
        
        var gameModel = GameModel(gridSeed: uniqueSeed)
        gameModel.players = [
            Player(
                name: isPlayer1 ? GKLocalPlayer.local.displayName : getOpponentAlias() ?? "Unknown",
                colour: "brand_orange",
                movesRemaining: 6,
                profileImage: isPlayer1 ? localImage : getOpponentImage() ?? UIImage(systemName: "person.circle.fill")!),
            Player(
                name: isPlayer1 ? getOpponentAlias() ?? "Unknown" : GKLocalPlayer.local.displayName,
                colour: "brand_blue",
                movesRemaining: 6,
                profileImage: isPlayer1 ? getOpponentImage() ?? UIImage(systemName: "person.circle.fill")! : localImage)
        ]
        
        currentMatchmakerVC?.dismiss(animated: true)
        
        do {
            try currentMatch?.sendData(toAllPlayers: JSONEncoder().encode(LeaderboardManager.shared.getElo()), with: .reliable)
        } catch {
            print("Failed to send Elo to players")
        }
        
        
        NotificationCenter.default.post(name: .presentGame, object: gameModel)
    }
    
    func determineFirstPlayer(usingSeed seed: Int, in match: GKMatch) -> String {
        let players = [match.players.first?.displayName ?? "", GKLocalPlayer.local.displayName].sorted()
        
        var rng = SeededGenerator(seed: seed)
        
        return players.randomElement(using: &rng)!
    }
    
    private func waitForPlayersToConnect(match: GKMatch, maxWaitTime: TimeInterval = 5.0) {
        var elapsedTime: TimeInterval = 0
        let checkInterval: TimeInterval = 1.0  // Check every second

        let timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            if match.expectedPlayerCount == 0 {
                print("All players connected! Starting match.")
                timer.invalidate()
                self.startMatch(match: match)
            } else {
                elapsedTime += checkInterval
                print("Waiting for players... (\(elapsedTime)s elapsed)")

                if elapsedTime >= maxWaitTime {
                    print("Timeout: Not all players connected.")
                    timer.invalidate()
                    match.disconnect()
                    self.currentMatchmakerVC?.dismiss(animated: true)
                }
            }
        }

        RunLoop.main.add(timer, forMode: .common)
    }
    
    func sendMove(_ move: (Int,Int)) {
        do {
            let moveData = Move(player: GKLocalPlayer.local.displayName, coords: move)
            let data = try JSONEncoder().encode(moveData)
            try currentMatch?.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
}

extension GameCenterHelper: GKMatchmakerViewControllerDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        print("Dismissing MVC")
        
        waitForPlayersToConnect(match: match)
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
                NotificationCenter.default.post(name: .gameEnded, object: localAlias)
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
        
        if let move = try? JSONDecoder().decode(Move.self, from: data) {
            NotificationCenter.default.post(name: .moveReceived, object: move)
            return
        }
        
        if let opponentElo = try? JSONDecoder().decode(Int.self, from: data) {
            LeaderboardManager.shared.opponentElo = opponentElo
        }
    }
}



extension Notification.Name {
    static let presentGame = Notification.Name(rawValue: "presentGame")
    static let moveReceived = Notification.Name(rawValue: "moveReceived")
    static let authenticationChanged = Notification.Name(rawValue: "authenticationChanged")
    static let gameEnded = Notification.Name(rawValue: "gameEnded")
}
