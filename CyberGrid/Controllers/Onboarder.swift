//
//  Onboarder.swift
//  CyberGrid
//
//  Created by Robert Haynes on 18/02/2025.
//
import UIKit
import OnboardKit

final class Onboarder {
    static let shared = Onboarder()
    
    func getOnboardingVC(before root: UIViewController, in window: UIWindow?) -> OnboardViewController {
        let pages = getPages()
        let onBoardingViewController = OnboardViewController(pageItems: pages, appearanceConfiguration: getAppearance()) {
            UserDefaults.standard.set(true, forKey: "onBoardingCompleted")
            
            DispatchQueue.main.async {
                window?.rootViewController = root
                window?.makeKeyAndVisible()
            }
        }
        
        return onBoardingViewController
    }
    
    func presentOnboarding(from root: UIViewController) {
        let pages = getPages()
        let onBoardingViewController = OnboardViewController(pageItems: pages, appearanceConfiguration: getAppearance()) {
            UserDefaults.standard.set(true, forKey: "onBoardingCompleted")
        }
        
        onBoardingViewController.modalPresentationStyle = .fullScreen
        onBoardingViewController.presentFrom(root, animated: true)
    }
    
    func getAppearance() -> OnboardViewController.AppearanceConfiguration {
        return OnboardViewController.AppearanceConfiguration(tintColor: .white,
                                                                       titleColor: .white,
                                                                       textColor: .white,
                                                                       backgroundColor: .black,
                                                                       imageContentMode: .scaleAspectFit,
                                                                       titleFont: UIFont(name: "Orbitron", size: 32.0) ?? UIFont.boldSystemFont(ofSize: 32.0),
                                                                       textFont: UIFont(name: "Orbitron", size: 17.0) ?? UIFont.boldSystemFont(ofSize: 17.0))
    }
    
    func getPages() -> [OnboardPage] {
        let pageOne = OnboardPage(title: "Welcome to CyberGrid",
                               imageName: "onboarding-1",
                               description: "A puzzle game where you hack your way to victory.")
        let pageTwo = OnboardPage(title: "Hacking Nodes",
                               imageName: "onboarding-2",
                               description: "Hack and capture your opponents nodes by outflanking their defenses. Valid moves are shown by coloured outlines.")
        let pageThree = OnboardPage(title: "Firewalls",
                               imageName: "onboarding-3",
                               description: "4 firewalls are randomly placed in the Grid. You can only outflank a firewall if your line contains a firewall. Find them to gain an advantage.")
        let pageFour = OnboardPage(title: "Winning the Game",
                               imageName: "onboarding-4",
                               description: "The opponent with the most nodes after all are played moves wins. Or if your opponent has no valid moves, you win!")
        let pageFive = OnboardPage(title: "Scores and Leaderboards",
                               imageName: "onboarding-5",
                                   description: "Gain score by practicing against the AI and climb the multiplayer ranks by improving your Elo against other players.")
                                   
        return [pageOne, pageTwo, pageThree, pageFour, pageFive]
    }
}
