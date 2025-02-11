//
//  ViewController.swift
//  Rummikub
//
//  Created by Robert Haynes on 2024/11/11.
//

import UIKit
import GameKit

class LandingViewController: UIViewController {

    @IBOutlet weak var multiplayerButton: UIButton!
    
    var gameModel: GameModel? = nil
    var selectedGameMode: GameMode? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        GameCenterHelper.helper.viewController = self
        
        multiplayerButton.isEnabled = GameCenterHelper.isAuthenticated
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(authenticationChanged(_:)),
          name: .authenticationChanged,
          object: nil
        )
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(presentGame(_:)),
          name: .presentGame,
          object: nil
        )
    }
    
    @IBAction func multiplayerPressed(_ sender: UIButton) {
        selectedGameMode = .online
        GameCenterHelper.helper.presentMatchmaker()
    }
    
    @IBAction func localPlayPressed(_ sender: UIButton) {
        selectedGameMode = .local
        
        self.gameModel = GameModel()
        
        self.gameModel!.players = [
            Player(
                name: GameCenterHelper.helper.localAlias ?? "",
                colour: "brand_orange",
                movesRemaining: 6,
                profileImage: GameCenterHelper.helper.localImage),
            Player(
                name: "Sirius",
                colour: "brand_blue",
                movesRemaining: 6,
                profileImage: UIImage(named: "robot")!)
        ]
        
        performSegue(withIdentifier: "goToGame", sender: self)
    }
    
    // MARK: - Notifications

    @objc private func authenticationChanged(_ notification: Notification) {
        multiplayerButton.isEnabled = notification.object as? Bool ?? false
    }
    
    @objc private func presentGame(_ notification: Notification) {
        guard let gameModel = notification.object as? GameModel else { return }
        
        self.gameModel = gameModel
        self.performSegue(withIdentifier: "goToGame", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToGame" {
            let gameVC = segue.destination as! GameViewController
            gameVC.gameModel = self.gameModel!
            gameVC.gameMode = self.selectedGameMode!
        }
    }
}

