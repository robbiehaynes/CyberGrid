//
//  LandingViewControllerTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//

import XCTest
import GameKit
@testable import CyberGrid

class LandingViewControllerTests: XCTestCase {
    var sut: LandingViewController!
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        sut = storyboard.instantiateViewController(identifier: "LandingViewController") as? LandingViewController
        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testViewDidAppear_EnablesAccessPoint() {
        sut.viewDidAppear(true)
        XCTAssertTrue(GKAccessPoint.shared.isActive, "Access point should be activated if onboarding is completed")
    }
    
    func testViewDidDisappear_DisablesAccessPoint() {
        sut.viewDidDisappear(true)
        XCTAssertFalse(GKAccessPoint.shared.isActive, "Access point should be deactivated when view disappears")
    }
    
    func testAuthenticationChanged_UpdatesMultiplayerButton() {
        NotificationCenter.default.post(name: .authenticationChanged, object: true)
        XCTAssertTrue(sut.multiplayerButton.isEnabled, "Multiplayer button should be enabled when authenticated")
    }
    
    func testLocalPlayPressed_InitializesGameModel() {
        UserDefaults.standard.set(false, forKey: "aiFirst")
        UserDefaults.standard.set(6, forKey: "numOfMoves")
        
        sut.localPlayPressed(UIButton())
        XCTAssertNotNil(sut.gameModel, "Game model should be initialized")
        XCTAssertEqual(sut.gameModel?.players.count, 2, "There should be two players initialized")
    }
    
    func testPrepareForSegue_PassesDataToGameViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let gameVC = storyboard.instantiateViewController(identifier: "GameViewController") as! GameViewController
        let segue = UIStoryboardSegue(identifier: "goToGame", source: sut, destination: gameVC)
        
        let gameModel = GameModel(gridSeed: 5678)
        sut.gameModel = gameModel
        sut.selectedGameMode = .local
        
        sut.prepare(for: segue, sender: self)
        
        XCTAssertEqual(gameVC.gameModel?.grid.seed, 5678, "Game model should be passed correctly")
        XCTAssertEqual(gameVC.gameMode, .local, "Game mode should be passed correctly")
    }
}

class MockLandingViewController: LandingViewController {
    var segueExpectation: XCTestExpectation?
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        if identifier == "goToGame" {
            segueExpectation?.fulfill()
        }
    }
}
