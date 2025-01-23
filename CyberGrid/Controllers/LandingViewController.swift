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
        GameCenterHelper.helper.presentMatchmaker()
    }
    
    @IBAction func localPlayPressed(_ sender: UIButton) {
        self.gameModel = GameModel()
        
        self.gameModel!.players = [
            Player(
                name: GameCenterHelper.helper.localAlias ?? "",
                colour: "coral",
                movesRemaining: 6,
                profileImage: GameCenterHelper.helper.localImage),
            Player(
                name: "Sirius",
                colour: "turqoise",
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
        guard let match = notification.object as? GKTurnBasedMatch else { return }
        
        loadAndDisplay(match: match)
    }
    
    //MARK: - Helpers
    private func loadAndDisplay(match: GKTurnBasedMatch) {
        
        match.loadMatchData() { data, error in
            
            if let data {
                if data.isEmpty {
                    self.gameModel = GameModel()
                } else {
                    self.gameModel = try? PropertyListDecoder().decode(GameModel.self, from: data)
                    guard (self.gameModel != nil) else { return }
                }
            } else {
                self.gameModel = GameModel()
            }
            
            GameCenterHelper.helper.currentMatch = match
            
            self.gameModel!.players = [
                Player(
                    name: GameCenterHelper.helper.localAlias ?? "",
                    colour: "coral",
                    movesRemaining: 6,
                    profileImage: GameCenterHelper.helper.localImage),
                Player(
                    name: GameCenterHelper.helper.getOpponentAlias() ?? "",
                    colour: "coral",
                    movesRemaining: 6,
                    profileImage: GameCenterHelper.helper.getOpponentImage() ?? UIImage(systemName: "person.circle.fill")!)
            ]
            
            self.performSegue(withIdentifier: "goToGame", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToGame" {
            let gameVC = segue.destination as! GameViewController
            gameVC.gameModel = self.gameModel!
        }
    }
}

