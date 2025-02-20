//
//  OnboarderTests.swift
//  CyberGrid
//
//  Created by Robert Haynes on 19/02/2025.
//

import XCTest
import OnboardKit
@testable import CyberGrid

class OnboarderTests: XCTestCase {
    var sut: Onboarder!
    var mockWindow: UIWindow!
    var mockRootViewController: UIViewController!
    
    override func setUp() {
        super.setUp()
        sut = Onboarder.shared
        mockWindow = UIWindow()
        mockRootViewController = UIViewController()
    }
    
    override func tearDown() {
        sut = nil
        mockWindow = nil
        mockRootViewController = nil
        super.tearDown()
    }
    
    func testGetOnboardingVC_ReturnsOnboardViewController() {
        let onboardingVC = sut.getOnboardingVC(before: mockRootViewController, in: mockWindow)
        XCTAssertNotNil(onboardingVC, "Onboarding VC should be created")
    }
    
    func testGetPages_ReturnsCorrectNumberOfPages() {
        let pages = sut.getPages()
        XCTAssertEqual(pages.count, 5, "There should be exactly 5 onboarding pages")
    }
    
    func testPresentOnboarding_PresentsOnboardingVC() {
        let rootVC = MockViewController()
        
        sut.presentOnboarding(from: rootVC)
        XCTAssertTrue(rootVC.didPresent, "Onboarding VC should be presented")
    }
}

class MockViewController: UIViewController {
    var didPresent = false
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didPresent = true
        completion?()
    }
}
