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
            
//            if let data {
//                if data.isEmpty {
//                    self.gameModel = GameModel()
//                } else {
//                    self.gameModel = try? PropertyListDecoder().decode(GameModel.self, from: data)
//                    guard (self.gameModel != nil) else { return }
//                }
//            } else {
//                self.gameModel = GameModel()
//            }
            
            GameCenterHelper.helper.currentMatch = match
            
//            self.gameModel!.instantiatePlayers(
//                localPlayer: GameCenterHelper.helper.localAlias ?? "",
//                opponents: GameCenterHelper.helper.getOpponentAliases())
//            
//            let gameVC = TestGameViewController()
//            gameVC.gameModel = self.gameModel!
//            gameVC.modalPresentationStyle = .fullScreen
//            self.present(gameVC, animated: true)
        }
    }
}

