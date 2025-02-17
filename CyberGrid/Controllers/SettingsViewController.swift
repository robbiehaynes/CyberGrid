//
//  SettingsViewController.swift
//  CyberGrid
//
//  Created by Robert Haynes on 17/02/2025.
//

import UIKit

class SettingsViewController: UIViewController {
    
    enum SegmentType {
        case playerFirst
        case numOfMoves
        case aiDifficulty
    }
    
    @IBOutlet weak var playerFirstControl: UISegmentedControl!
    @IBOutlet weak var numOfMovesControl: UISegmentedControl!
    @IBOutlet weak var aiDifficultyControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setSelectedSegments()
    }
    
    @IBAction func exitButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true)
    }

    @IBAction func segmentSelected(_ sender: UISegmentedControl) {
        switch determineSegmentType(from: sender) {
            case .playerFirst:
                UserDefaults.standard.set(sender.titleForSegment(at: sender.selectedSegmentIndex) == "Yes",
                                          forKey: "playerFirst")
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
        let playerFirst: Bool = UserDefaults.standard.bool(forKey: "playerFirst")
        let numOfMoves: Int = UserDefaults.standard.integer(forKey: "numOfMoves")
        let aiDifficulty: Int = UserDefaults.standard.integer(forKey: "aiDifficulty")
        
        playerFirstControl.selectedSegmentIndex = playerFirst ? 0 : 1
        numOfMovesControl.selectedSegmentIndex = numOfMoves - 4
        aiDifficultyControl.selectedSegmentIndex = aiDifficulty
    }
}
