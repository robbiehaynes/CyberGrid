//
//  ViewController.swift
//  Rummikub
//
//  Created by Robert Haynes on 2024/11/11.
//

import UIKit
import GameKit
import GoogleMobileAds

class LandingViewController: UIViewController {

    @IBOutlet weak var multiplayerButton: UIButton!
    
    var gameModel: GameModel? = nil
    var selectedGameMode: GameMode? = nil
    private var isMobileAdsStartCalled = false
    
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
        
        GoogleMobileAdsConsentManager.shared.gatherConsent(from: self) { [weak self] consentError in
            guard let self else { return }
            
            if let consentError {
                // Consent gathering failed.
                print("Error: \(consentError.localizedDescription)")
            }
            
            if GoogleMobileAdsConsentManager.shared.canRequestAds {
                self.startGoogleMobileAdsSDK()
            }
            
//            self.privacySettingsButton.isEnabled =
//            GoogleMobileAdsConsentManager.shared.isPrivacyOptionsRequired
        }
        
        // This sample attempts to load ads using consent obtained in the previous session.
        if GoogleMobileAdsConsentManager.shared.canRequestAds {
            startGoogleMobileAdsSDK()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GameCenterHelper.helper.setAccessPointIsActive(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        GameCenterHelper.helper.setAccessPointIsActive(false)
    }
    
    @IBAction func settingsButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "goToSettings", sender: self)
    }
    
    @IBAction func multiplayerPressed(_ sender: UIButton) {
        selectedGameMode = .online
        GameCenterHelper.helper.presentMatchmaker()
    }
    
    @IBAction func localPlayPressed(_ sender: UIButton) {
        selectedGameMode = .local
        
        let seed = GridSeedGenerator.shared.generateSeed(player1ID: GKLocalPlayer.local.gamePlayerID, player2ID: "Sirius")
        let userFirst = !UserDefaults.standard.bool(forKey: "aiFirst")
        let numOfMoves = UserDefaults.standard.integer(forKey: "numOfMoves")
        self.gameModel = GameModel(gridSeed: seed)
        
        self.gameModel!.players = [
            Player(
                name: userFirst ? GameCenterHelper.helper.localAlias ?? "" : "Sirius",
                colour: "brand_orange",
                movesRemaining: numOfMoves,
                profileImage: userFirst ? GameCenterHelper.helper.localImage : UIImage(named: "robot")!),
            Player(
                name: userFirst ? "Sirius" : GameCenterHelper.helper.localAlias ?? "",
                colour: "brand_blue",
                movesRemaining: numOfMoves,
                profileImage: userFirst ? UIImage(named: "robot")! : GameCenterHelper.helper.localImage)
        ]
        
        performSegue(withIdentifier: "goToGame", sender: self)
    }
    
    private func startGoogleMobileAdsSDK() {
        DispatchQueue.main.async {
          guard !self.isMobileAdsStartCalled else { return }

          self.isMobileAdsStartCalled = true

          // Initialize the Google Mobile Ads SDK.
          MobileAds.shared.start()
        }
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

