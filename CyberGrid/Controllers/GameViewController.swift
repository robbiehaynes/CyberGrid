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
    var fortifying = false
    var usingVirus = false
    let agent = Agent(depth: 7)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let gameModel = gameModel else { return }
        
        self.gameModel!.grid.initialSetup(players: gameModel.players)
        self.currentPlayer = gameModel.players[0]
        self.profileImage.layer.cornerRadius = 25
        self.profileImage.image = currentPlayer!.profileImage.image ?? UIImage(systemName: "person.circle.fill")
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(gameModelChanged(_:)),
          name: .gameModelChanged,
          object: nil
        )
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(gameEnded(_:)),
          name: .gameEnded,
          object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playerLabel.text = currentPlayer!.name
        playerLabel.textColor = UIColor(named: currentPlayer!.colour)
        updateUI()
    }
    
    @IBAction func nodeButtonPressed(_ sender: UIButton) {
        var row = 0
        if sender.tag != 36 { row = sender.tag / 6 }
        let col = sender.tag % 6
        
        performAction(atRow: row, atCol: col)
    }
    
    @IBAction func hackButtonPressed(_ sender: UIButton) {
        fortifying = false
        actionLabel.text = "Hacking..."
        updateUI()
    }
    
    @IBAction func fortifyButtonPressed(_ sender: UIButton) {
        fortifying = true
        actionLabel.text = "Fortifying..."
        updateUI()
    }
    
    @objc private func gameModelChanged(_ notification: Notification) {
        guard let gameModel = notification.object as? GameModel else { return }
        
        self.gameModel = gameModel
        updateUI()
        if gameModel.winner != nil {
            NotificationCenter.default.post(name: .gameEnded, object: gameModel.winner)
        }
    }
    
    @objc private func gameEnded(_ notification: Notification) {
        // Someone won, notify user
        guard let winner = notification.object as? String else { return }
        
        if winner == GameCenterHelper.helper.localAlias {
            let alert = UIAlertController(title: "Winner!", message: "\(winner) has won the game!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
                self.dismiss(animated: true)
            })
            self.present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Unlucky!", message: "\(winner) has won the game.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
                self.dismiss(animated: true)
            })
            self.present(alert, animated: true)
        }
        
    }
    
    func performAction(atRow row: Int, atCol col: Int) {
        if fortifying {
            gameModel!.grid.nodes[row][col].fortify()
        } else {
            gameModel!.grid.nodes[row][col].attack(player: currentPlayer!)
            
            if gameModel!.grid.nodes[row][col].powerup == .firewall {
                let alert = UIAlertController(
                    title: "PowerUp Found",
                    message: "You have discovered a firewall. This node starts stronger!",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(alert, animated: true)
            }
        }
        
        gameModel!.grid.recalculateOwners(fromCoords: (row, col))
        gameModel!.useTurn(for: currentPlayer!)
        switchPlayer()
        
        if gameMode == .online {
            GameCenterHelper.helper.sendModel(gameModel!)
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
        
        movesRemainingLabel.text = "Moves Remaining: \(currentPlayer.movesRemaining)"
        let moves = gameModel.grid.validMoves(for: currentPlayer, fortifying)
        
        if moves.isEmpty && gameModel.grid.validMoves(for: currentPlayer, !fortifying).isEmpty {
            switchPlayer()
            return
        }
        
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
                        button.setBackgroundImage(UIImage(named: "\(owner.colour)_chip_\(node.health)"), for: .normal)
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
        playerLabel.text = currentPlayer!.name
        playerLabel.textColor = UIColor(named: currentPlayer!.colour)
        profileImage.image = currentPlayer!.profileImage.image ?? UIImage(systemName: "person.circle.fill")
        
        updateUI()
    }
    
    func performAIMove() {
        guard let currentPlayer = currentPlayer, let gameModel = gameModel else { return }
        
        animateThinkingLabel()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Compute the best move
            if let move = self.agent.bestMove(for: currentPlayer, on: gameModel.grid) {
                
                DispatchQueue.main.async {
                    // Show move decision
                    self.actionLabel.text = "\(currentPlayer.name) chose \(move)"
                    self.actionLabel.layer.removeAllAnimations()
                    
                    // Apply move and update game state
                    self.gameModel!.grid.applyMove(move, for: currentPlayer)
                    self.gameModel!.grid.recalculateOwners(fromCoords: move)
                    self.gameModel!.useTurn(for: currentPlayer)
                    
                    if let winner = self.gameModel!.winner {
                        self.updateUI()
                        NotificationCenter.default.post(name: .gameEnded, object: winner)
                    } else {
                        self.switchPlayer()
                    }
                }
            }
        }
    }
    
    func animateThinkingLabel() {
        actionLabel.text = "\(currentPlayer!.name) is thinking"
        actionLabel.alpha = 1.0
        
        let dotAnimation = CAKeyframeAnimation(keyPath: "opacity")
        dotAnimation.values = [1.0, 0.3, 1.0]
        dotAnimation.keyTimes = [0, 0.5, 1]
        dotAnimation.duration = 1.2
        dotAnimation.repeatCount = .infinity
        
        actionLabel.layer.add(dotAnimation, forKey: "thinkingAnimation")
    }

}
