//
//  SettingsViewController.swift
//  CyberGrid
//
//  Created by Robert Haynes on 17/02/2025.
//

import UIKit
import StoreKit

class SettingsViewController: UIViewController {
    
    enum SegmentType {
        case playerFirst
        case numOfMoves
        case aiDifficulty
    }
    
    @IBOutlet weak var playerFirstControl: UISegmentedControl!
    @IBOutlet weak var numOfMovesControl: UISegmentedControl!
    @IBOutlet weak var aiDifficultyControl: UISegmentedControl!
    @IBOutlet weak var removeAdsButton: UIButton!
    
    var product: Product?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setSelectedSegments()
        
        removeAdsButton.isEnabled = !(Store.shared.purchasedProducts.count > 0)
        removeAdsButton.setTitle("Ads Successfully Removed", for: .disabled)
        if let product {
            removeAdsButton.setTitle("\(product.displayName) for \(product.displayPrice)", for: .normal)
        }
    }
    
    @IBAction func exitButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true)
    }

    @IBAction func segmentSelected(_ sender: UISegmentedControl) {
        switch determineSegmentType(from: sender) {
            case .playerFirst:
                UserDefaults.standard.set(sender.titleForSegment(at: sender.selectedSegmentIndex) == "No",
                                          forKey: "aiFirst")
            case .numOfMoves:
                let numOfMoves = Int(sender.titleForSegment(at: sender.selectedSegmentIndex) ?? "0")
                UserDefaults.standard.set(numOfMoves, forKey: "numOfMoves")
            case .aiDifficulty:
                switch sender.titleForSegment(at: sender.selectedSegmentIndex) {
                    case "Easy":
                        UserDefaults.standard.set(0, forKey: "aiDifficulty")
                    case "Medium":
                        UserDefaults.standard.set(1, forKey: "aiDifficulty")
                    default:
                        UserDefaults.standard.set(2, forKey: "aiDifficulty")
                }
        }
    }
    
    func determineSegmentType(from sender: UISegmentedControl) -> SegmentType {
        switch sender.titleForSegment(at: 0) {
        case "Yes":
            return .playerFirst
        case "4":
            return .numOfMoves
        case "Easy":
            return .aiDifficulty
        default:
            return .playerFirst
        }
    }

    func setSelectedSegments() {
        let aiFirst: Bool = UserDefaults.standard.bool(forKey: "aiFirst")
        let numOfMoves: Int = UserDefaults.standard.integer(forKey: "numOfMoves")
        let aiDifficulty: Int = UserDefaults.standard.integer(forKey: "aiDifficulty")
        
        playerFirstControl.selectedSegmentIndex = aiFirst ? 1 : 0
        numOfMovesControl.selectedSegmentIndex = numOfMoves - 4
        aiDifficultyControl.selectedSegmentIndex = aiDifficulty
    }
    
    @IBAction func removeAdsPressed(_ sender: UIButton) {
        Task {
            if let product {
                let _ = try await Store.shared.purchaseProduct(product)
                removeAdsButton.isEnabled = !(Store.shared.purchasedProducts.count > 0)
            }
        }
    }
    
    @IBAction func restorePurchasesPressed(_ sender: UIButton) {
        Task {
            do {
                try await Store.shared.restorePurchases()
                removeAdsButton.isEnabled = !(Store.shared.purchasedProducts.count > 0)
            } catch {
                print("Error restoring purchases: \(error)")
            }
        }
    }
}
