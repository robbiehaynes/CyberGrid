//
//  SettingsViewControllerTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//

import XCTest
@testable import CyberGrid

class SettingsViewControllerTests: XCTestCase {
    var sut: SettingsViewController!
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        sut = storyboard.instantiateViewController(identifier: "SettingsViewController") as? SettingsViewController
        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testViewDidLoad_SetsSelectedSegments() {
        UserDefaults.standard.set(false, forKey: "aiFirst")
        UserDefaults.standard.set(5, forKey: "numOfMoves")
        UserDefaults.standard.set(1, forKey: "aiDifficulty")
        
        sut.setSelectedSegments()
        
        XCTAssertEqual(sut.playerFirstControl.selectedSegmentIndex, 0)
        XCTAssertEqual(sut.numOfMovesControl.selectedSegmentIndex, 1)
        XCTAssertEqual(sut.aiDifficultyControl.selectedSegmentIndex, 1)
    }
    
    func testSegmentSelected_PlayerFirst() {
        let segmentedControl = UISegmentedControl(items: ["Yes", "No"])
        segmentedControl.selectedSegmentIndex = 1
        
        sut.segmentSelected(segmentedControl)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "aiFirst"))
    }
    
    func testSegmentSelected_NumOfMoves() {
        let segmentedControl = UISegmentedControl(items: ["4", "5", "6"])
        segmentedControl.selectedSegmentIndex = 2
        
        sut.segmentSelected(segmentedControl)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "numOfMoves"), 6)
    }
    
    func testSegmentSelected_AIDifficulty() {
        let segmentedControl = UISegmentedControl(items: ["Easy", "Medium", "Hard"])
        segmentedControl.selectedSegmentIndex = 1
        
        sut.segmentSelected(segmentedControl)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "aiDifficulty"), 1)
    }
    
    func testDetermineSegmentType() {
        let playerFirstControl = UISegmentedControl(items: ["Yes", "No"])
        XCTAssertEqual(sut.determineSegmentType(from: playerFirstControl), .playerFirst)
        
        let numOfMovesControl = UISegmentedControl(items: ["4", "5", "6"])
        XCTAssertEqual(sut.determineSegmentType(from: numOfMovesControl), .numOfMoves)
        
        let aiDifficultyControl = UISegmentedControl(items: ["Easy", "Medium", "Hard"])
        XCTAssertEqual(sut.determineSegmentType(from: aiDifficultyControl), .aiDifficulty)
    }
    
    func testExitButtonPressed_DismissesViewController() {
        let expectation = expectation(description: "View controller should be dismissed")
        
        let mockVC = MockSettingsViewController()
        mockVC.dismissExpectation = expectation
        mockVC.exitButtonPressed(UIButton())
        
        wait(for: [expectation], timeout: 1.0)
    }
}

class MockSettingsViewController: SettingsViewController {
    var dismissExpectation: XCTestExpectation?
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissExpectation?.fulfill()
    }
}
