//
//  GameViewController.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

import UIKit

class GameViewController: UIViewController {

    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var movesRemainingLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    var gameModel: GameModel?
    var currentPlayer: Player?
    var fortifying = false
    var usingVirus = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let gameModel = gameModel else { return }
        
        self.gameModel!.grid.initialSetup(players: gameModel.players)
        self.currentPlayer = gameModel.players[0]
        self.profileImage.layer.cornerRadius = 25
        self.profileImage.image = currentPlayer!.profileImage.image ?? UIImage(systemName: "person.circle.fill")
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
        updateUI()
        if let winner = gameModel?.winner {
            // Someone won, notify user
            let alert = UIAlertController(title: "Winner!", message: "\(winner) has won the game!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func updateUI() {
        guard let gameModel else { return }
        guard let currentPlayer else { return }
        
        movesRemainingLabel.text = "Moves Remaining: \(currentPlayer.movesRemaining)"
        let moves = gameModel.grid.validMoves(for: currentPlayer, fortifying)
        
        if moves.isEmpty && gameModel.grid.validMoves(for: currentPlayer, !fortifying).isEmpty {
            switchPlayer()
            updateUI()
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
    }
}
