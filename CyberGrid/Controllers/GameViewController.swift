//
//  GameViewController.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

import UIKit

enum GameMode {
    case local
    case online
}

class GameViewController: UIViewController {

    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var movesRemainingLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    var gameModel: GameModel?
    var currentPlayer: Player?
    var gameMode: GameMode = .local
    let agent = MiniAgent(difficulty: UserDefaults.standard.integer(forKey: "aiDifficulty"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let gameModel = gameModel else { return }
        
        self.gameModel!.grid.initialSetup(players: gameModel.players)
        self.currentPlayer = gameModel.players[0]
        self.profileImage.layer.cornerRadius = 25
        self.profileImage.image = currentPlayer!.profileImage.image ?? UIImage(systemName: "person.circle.fill")
        
        playerLabel.text = currentPlayer!.name
        playerLabel.textColor = UIColor(named: currentPlayer!.colour)
        updateUI()
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(moveReceived(_:)),
          name: .moveReceived,
          object: nil
        )
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(gameEnded(_:)),
          name: .gameEnded,
          object: nil
        )
        
        if !currentPlayer!.isLocal() {
            opponentIsThinking(true)
            if gameMode == .local { performAIMove() }
        }
        GameCenterHelper.helper.setAccessPointIsActive(false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        GameCenterHelper.helper.setAccessPointIsActive(true)
        super.viewDidDisappear(animated)
    }
    
    @IBAction func exitButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "", message: "Would like to forfeit?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            if self.gameMode == .online {
                GameCenterHelper.helper.currentMatch?.disconnect()
            }
            self.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    @IBAction func nodeButtonPressed(_ sender: UIButton) {
        var row = 0
        if sender.tag != 36 { row = sender.tag / 6 }
        let col = sender.tag % 6
        
        performAction(atRow: row, atCol: col)
    }
    
    @objc private func moveReceived(_ notification: Notification) {
        guard let move = notification.object as? Move else { return }
        
        let moveCoords = (move.row, move.column)
        let player = gameModel?.getPlayerByName(move.player)
        
        // Apply move and update game state
        gameModel!.grid.applyMove(moveCoords, for: player!)
        gameModel!.useTurn(for: player!)
        opponentIsThinking(false)
        
        if let winner = gameModel!.winner {
            updateUI()
            NotificationCenter.default.post(name: .gameEnded, object: winner)
        } else {
            switchPlayer()
        }
    }
    
    @objc private func gameEnded(_ notification: Notification) {
        // Someone won, notify user
        guard let winner = notification.object as? String else { return }
        let didWin = winner == GameCenterHelper.helper.localAlias
        
        if gameMode == .online {
            if let opponent = GameCenterHelper.helper.currentOpponent {
                LeaderboardManager.shared.onlineGameCompleted(against: opponent, didWin: didWin)
            } else {
                print("No opponent found")
            }
        } else {
            let aiDifficulty = UserDefaults.standard.integer(forKey: "aiDifficulty")
            LeaderboardManager.shared.localGameCompleted(withDifficulty: aiDifficulty, didWin: didWin)
        }
        
        actionLabel.text = didWin ? "You win! Going back to menu..." : "You lose! Going back to menu..."
        let alert = UIAlertController(title: didWin ? "Winner!" : "Unlucky!",
                                      message: gameMode == .local
                                      ? "\(winner) has won the game! Your new score is: \(LeaderboardManager.shared.getSPScore())"
                                      : "\(winner) has won the game! Your new Elo is \(LeaderboardManager.shared.getElo())", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.dismiss(animated: true)
            }
        })
        self.present(alert, animated: true)
    }
    
    func performAction(atRow row: Int, atCol col: Int) {
        
        gameModel!.grid.nodes[row][col].attack(player: currentPlayer!)
        
        if gameModel!.grid.nodes[row][col].powerup == .firewall {
            let alert = UIAlertController(
                title: "PowerUp Found",
                message: "You have discovered a firewall. This node starts stronger!",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(alert, animated: true)
        }
        
        gameModel!.grid.recalculateOwners(fromCoords: (row, col))
        gameModel!.useTurn(for: currentPlayer!)
        switchPlayer()
        
        if gameMode == .online {
            GameCenterHelper.helper.sendMove((row, col))
            opponentIsThinking(true)
        } else {
            performAIMove()
        }
        
        if gameModel!.winner != nil {
            NotificationCenter.default.post(name: .gameEnded, object: gameModel!.winner)
        }
    }
    
    func updateUI() {
        guard let gameModel else { return }
        guard let currentPlayer else { return }
        
        playerLabel.text = currentPlayer.name
        playerLabel.textColor = UIColor(named: currentPlayer.colour)
        profileImage.image = currentPlayer.profileImage.image ?? UIImage(systemName: "person.circle.fill")
        
        movesRemainingLabel.text = "Moves Remaining: \(currentPlayer.movesRemaining)"
        let moves = gameModel.grid.validMoves(for: currentPlayer)
        
        for row in 0..<6 {
            for col in 0..<6 {
                let node = gameModel.grid.nodes[row][col]
                var tag = row * 6 + col // Calculate the tag for each button
                if row == 0 && col == 0 {
                    tag = 36
                }
                if let button = view.viewWithTag(tag) as? UIButton {
                    // Update button background color based on the node owner
                    if let owner = node.owner {
                        if let image = UIImage(named: "\(owner.colour)_\(node.health)") {
                            animateButtonImageChange(button: button, newImage: image)
                        }
                    } else {
                        button.backgroundColor = .systemBackground // Default color for neutral nodes
                    }
                    
                    button.layer.cornerRadius = 2
                    
                    // Enable or disable button based on valid moves
                    if moves.contains(where: { $0 == (row, col) }) {
                        button.isEnabled = true
                        button.alpha = 1.0 // Fully visible for valid moves
                        if node.owner == nil {
                            button.layer.borderWidth = 3
                            button.layer.borderColor = UIColor(named: currentPlayer.colour)?.cgColor
                        }
                    } else {
                        button.isEnabled = false
                        button.layer.borderWidth = 0
                        if node.owner == nil {
                            button.alpha = 0.5 // Dimmed for invalid moves
                        }
                    }
                }
            }
        }
    }
    
    func switchPlayer() {
        guard let gameModel = gameModel else { return }
        
        currentPlayer = gameModel.players.first(where: { $0 != currentPlayer })
        
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    
    func performAIMove() {
        guard let currentPlayer = currentPlayer, let gameModel = gameModel else { return }
        
        opponentIsThinking(true)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Compute the best move
            if let move = self.agent.bestMove(for: currentPlayer, on: gameModel.grid) {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // Send move
                    NotificationCenter.default.post(name: .moveReceived,
                                                    object: Move(player: currentPlayer.name, coords: move))
                }
            } else {
                NotificationCenter.default.post(name: .gameEnded,
                                                object: GameCenterHelper.helper.localAlias)
            }
        }
    }
    
    func setButtonStates(to enabled: Bool) {
        for row in 0..<6 {
            for col in 0..<6 {
                var tag = row * 6 + col // Calculate the tag for each button
                if row == 0 && col == 0 {
                    tag = 36
                }
                if let button = view.viewWithTag(tag) as? UIButton {
                    DispatchQueue.main.async {
                        button.isEnabled = enabled
                        button.alpha = enabled ? 1.0 : 0.5
                    }
                }
            }
        }
    }
    
    func opponentIsThinking(_ thinking: Bool) {
        if !thinking {
            actionLabel.layer.removeAllAnimations()
            actionLabel.text = "Your turn, make a decision..."
            setButtonStates(to: true)
            return
        }
        
        setButtonStates(to: false)
        actionLabel.text = "\(currentPlayer!.name) is thinking"
        actionLabel.alpha = 1.0
        
        let dotAnimation = CAKeyframeAnimation(keyPath: "opacity")
        dotAnimation.values = [1.0, 0.3, 1.0]
        dotAnimation.keyTimes = [0, 0.5, 1]
        dotAnimation.duration = 1.2
        dotAnimation.repeatCount = .infinity
        
        actionLabel.layer.add(dotAnimation, forKey: "thinkingAnimation")
    }

    func animateButtonImageChange(button: UIButton, newImage: UIImage) {
        
        let currentImage = button.backgroundImage(for: .normal)
        
        if currentImage != newImage {
            UIView.transition(with: button, duration: 0.75, options: .transitionFlipFromLeft, animations: {
                button.setBackgroundImage(newImage, for: .normal)
                button.setBackgroundImage(newImage, for: .disabled)
            }, completion: nil)
        }
    }

}
