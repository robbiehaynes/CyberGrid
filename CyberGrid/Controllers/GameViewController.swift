//
//  GameViewController.swift
//  CyberGrid
//
//  Created by Robert Haynes on 31/12/2024.
//

import UIKit

class GameViewController: UIViewController {

    @IBOutlet weak var movesRemainingLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    
    var playerOne = Player(name: "One", colour: "coral", movesRemaining: 10)
    var playerTwo = Player(name: "Two", colour: "turqoise", movesRemaining: 10)
    var gameModel: GameModel?
    var currentPlayer: Player?
    var fortifying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameModel = GameModel(players: [playerOne, playerTwo])
        currentPlayer = playerOne
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
    }
    
    @IBAction func fortifyButtonPressed(_ sender: UIButton) {
        fortifying = true
        actionLabel.text = "Fortifying..."
    }
    
    func performAction(atRow row: Int, atCol col: Int) {
        if fortifying {
            gameModel!.grid.nodes[row][col].fortify()
        } else {
            gameModel!.grid.nodes[row][col].attack(withVirus: false, player: currentPlayer!)
        }
        
        gameModel!.grid.recalculateOwners()
        updateUI()
        switchPlayer()
    }
    
    func updateUI() {
        guard let gameModel else { return }
        
        for row in 0..<6 {
            for col in 0..<6 {
                let node = gameModel.grid.nodes[row][col]
                var tag = row * 6 + col // Calculate the tag for each button
                if row == 0 && col == 0{
                    tag = 36
                }
                if let button = view.viewWithTag(tag) as? UIButton {
                    // Update button background color based on the node owner
                    if let owner = node.owner {
                        button.backgroundColor = UIColor(named: owner.colour)
                    } else {
                        button.backgroundColor = .black // Default color for neutral nodes
                    }
                    
                    // Update button title to display node health
                    button.setTitle("\(node.health)", for: .normal)
                }
            }
        }
    }
    
    func switchPlayer() {
        currentPlayer = (currentPlayer === playerOne) ? playerTwo : playerOne
    }
}
