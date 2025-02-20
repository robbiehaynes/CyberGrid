//
//  GameViewControllerTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//

import XCTest
@testable import CyberGrid

class GameViewControllerTests: XCTestCase {
    var sut: GameViewController!
    var mockGameModel: GameModel!
    var mockPlayer1: Player!
    var mockPlayer2: Player!
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        sut = storyboard.instantiateViewController(identifier: "GameViewController") as? GameViewController
        
        let image = UIImage(systemName: "person")!
        mockPlayer1 = Player(name: "Alice", colour: "Red", movesRemaining: 3, profileImage: image)
        mockPlayer2 = Player(name: "Bob", colour: "Blue", movesRemaining: 2, profileImage: image)
        mockGameModel = GameModel(players: [mockPlayer1, mockPlayer2], gridSeed: 42)
        sut.gameModel = mockGameModel
        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        mockGameModel = nil
        mockPlayer1 = nil
        mockPlayer2 = nil
        super.tearDown()
    }
    
    func testViewDidLoad_InitializesGame() {
        XCTAssertNotNil(sut.currentPlayer, "Current player should be set")
        XCTAssertEqual(sut.currentPlayer?.name, "Alice", "First player should be Alice")
        XCTAssertEqual(sut.playerLabel.text, "Alice", "Player label should show Alice's name")
    }
    
    func testExitButtonPressed_PresentsForfeitAlert() {
        let mockVC = MockGameViewController()
        mockVC.exitButtonPressed(UIButton())
        XCTAssertTrue(mockVC.didPresentAlert, "Forfeit alert should be presented")
    }
    
    func testNodeButtonPressed_CallsPerformAction() {
        let mockVC = MockGameViewController()
        let button = UIButton()
        button.tag = 10
        mockVC.nodeButtonPressed(button)
        XCTAssertEqual(mockVC.lastPerformedMove?.0, 1, "Row should be 1")
        XCTAssertEqual(mockVC.lastPerformedMove?.1, 4, "Column should be 4")
    }
    
    func testPerformAction_AppliesMoveAndSwitchesPlayer() {
        sut.performAction(atRow: 1, atCol: 2)
        XCTAssertNotEqual(sut.currentPlayer, mockPlayer1, "Current player should switch after move")
    }
    
    func testSwitchPlayer_ChangesCurrentPlayer() {
        sut.switchPlayer()
        XCTAssertEqual(sut.currentPlayer, mockPlayer2, "Current player should switch to the next player")
    }
    
    func testOpponentIsThinking_UpdatesUI() {
        sut.opponentIsThinking(true)
        XCTAssertEqual(sut.actionLabel.text, "Alice is thinking", "Action label should indicate opponent is thinking")
    }
}

class MockGameViewController: GameViewController {
    var didPresentAlert = false
    var lastPerformedMove: (Int, Int)?
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if viewControllerToPresent is UIAlertController {
            didPresentAlert = true
        }
        completion?()
    }
    
    override func performAction(atRow row: Int, atCol col: Int) {
        lastPerformedMove = (row, col)
    }
}
