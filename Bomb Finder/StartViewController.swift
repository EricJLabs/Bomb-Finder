//
//  StartViewController.swift
//  Bomb Finder
//
//  Created by Eric J on 12/24/18.
//  Copyright © 2018 Eric J. All rights reserved.
//

import UIKit
import GameKit

class StartViewController: UIViewController {
    
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var explosionLabel: UILabel!
    @IBOutlet weak var bombLabel: UILabel!
    @IBOutlet weak var levelSegmentedControl: UISegmentedControl!
    @IBOutlet weak var sizeSlider: UISlider!
    
    let gameCenterHelper = GameCenterHelper()
    
    var numberOfBombs: Int {
        guard let sizeText = sizeLabel.text,
            let size = Double(sizeText) else {
            preconditionFailure()
        }
        
        let percent: Double
        switch levelSegmentedControl.selectedSegmentIndex {
        case 0:
            percent = 0.124  // easy
        case 1:
            percent = 0.16// intermediate
        default:
            percent = 0.20 // hard
        }
        return Int(size * size * percent)
    }
    
    var leaderBoardID: String {
        guard let sizeText = sizeLabel.text,
            let size = Int(sizeText) else {
                preconditionFailure()
        }

        return String("com.ericjlabs.bomb_finder_\(size)_\(numberOfBombs)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        levelSegmentedControl.selectedSegmentIndex = Settings.shared.level.rawValue
        let size = Settings.shared.size
        sizeSlider.setValue(Float(size), animated: false)
        sizeLabel.text = String(size)
        let highScores = NSLocalizedString("com.ericjlabs.bombfinder.high-scores", value: "High Scores", comment: "Show the high scores.")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: highScores, style: .plain, target: self, action: #selector(onShowHighScores))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.openingAnimation()
        }
    }
    
    @IBAction func onLevelChanged(_ sender: UISegmentedControl) {
        Settings.shared.level = Level(rawValue: sender.selectedSegmentIndex) ?? .easy
    }
    
    @IBAction func onSizeChanged(_ sender: UISlider) {
        let size = Int(sender.value)
        sizeLabel.text = String(size)
        Settings.shared.size = size
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let gameViewController = segue.destination as? GameViewController,
            let sizeText = sizeLabel.text,
            let size = Int(sizeText) else {
            return
        }
        
        gameViewController.board = Board.create(size: size, numberOfBombs: numberOfBombs)
        gameViewController.gameCenterHelper = gameCenterHelper
    }
    
    private func openingAnimation() {
        explosionLabel.transform = CGAffineTransform.init(scaleX: 0.3, y: 0.3).rotated(by: 0.25)
        UIView.animateKeyframes(withDuration: 0.6, delay: 0.0, options: .calculationModeLinear, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/3, animations: {
                self.explosionLabel.transform = CGAffineTransform.identity
                self.bombLabel.alpha = 0.0
                self.explosionLabel.alpha = 1.0
            })
            UIView.addKeyframe(withRelativeStartTime: 1/3, relativeDuration: 1/3, animations: {
                self.explosionLabel.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            })
            UIView.addKeyframe(withRelativeStartTime: 2/3, relativeDuration: 1/3, animations: {
                self.explosionLabel.transform = CGAffineTransform.init(scaleX: 1.1, y: 1.1)
            })
        }, completion: { _ in
            self.explosionLabel.transform = CGAffineTransform.identity
            self.bombLabel.alpha = 1.0
            self.explosionLabel.alpha = 0.0
        })
    }
    
    @objc private func onShowHighScores() {
        let gameCenterViewController = GKGameCenterViewController()
        gameCenterViewController.gameCenterDelegate = self
        gameCenterViewController.viewState = .leaderboards
        gameCenterViewController.leaderboardIdentifier = leaderBoardID
        
         present(gameCenterViewController, animated: true, completion: nil)
    }
}

extension StartViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
