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
    
    var fortifying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func nodeButtonPressed(_ sender: UIButton) {
        let row = sender.tag / 6
        let col = sender.tag % 6
        
        if !fortifying {
            actionLabel.text = "Hacking node [\(row)][\(col)]"
        } else {
            actionLabel.text = "Fortifying node [\(row)][\(col)]"
        }
    }
    
    @IBAction func hackButtonPressed(_ sender: UIButton) {
        fortifying = false
        actionLabel.text = "Hacking..."
    }
    
    @IBAction func fortifyButtonPressed(_ sender: UIButton) {
        fortifying = true
        actionLabel.text = "Fortifying..."
    }
    
}
