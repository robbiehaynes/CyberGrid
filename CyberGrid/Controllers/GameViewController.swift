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
    @IBOutlet weak var virusSwitch: UISwitch!
    @IBOutlet weak var virusLabel: UILabel!
    
    var playerOne = Player(name: "One", colour: "coral", movesRemaining: 6)
    var playerTwo = Player(name: "Two", colour: "turqoise", movesRemaining: 6)
    var gameModel: GameModel?
    var currentPlayer: Player?
    var fortifying = false
    var usingVirus = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameModel = GameModel(players: [playerOne, playerTwo])
        gameModel!.grid.initialSetup(players: [playerOne, playerTwo])
        currentPlayer = playerOne
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
    
    @IBAction func virusSwitchFlipped(_ sender: UISwitch) {
        usingVirus = sender.isOn
        if usingVirus {
            actionLabel.text = "Hacking with Virus..."
        } else {
            actionLabel.text = "Hacking..."
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
        currentPlayer = (currentPlayer === playerOne) ? playerTwo : playerOne
        playerLabel.text = currentPlayer!.name
        playerLabel.textColor = UIColor(named: currentPlayer!.colour)
    }
}
