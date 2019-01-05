//
//  StartViewController.swift
//  Bomb Finder
//
//  Created by Eric J on 12/24/18.
//  Copyright © 2018 Eric J. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
    
    @IBOutlet weak var bombsSlider: UISlider!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var bombsLabel: UILabel!
    @IBOutlet weak var explosionLabel: UILabel!
    @IBOutlet weak var bombLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.openingAnimation()
        }
    }
    
    @IBAction func onSizeChanged(_ sender: UISlider) {
        let size = Int(sender.value)
        sizeLabel.text = String(size)
        
        let newMaxBombs = Float(size * size / 2)
        bombsSlider.maximumValue = newMaxBombs
        if bombsSlider.value >= newMaxBombs {
            bombsSlider.value = Float(size)
        }
        bombsLabel.text = String(Int(bombsSlider.value))
    }
    
    @IBAction func onBombsChanged(_ sender: UISlider) {
        bombsLabel.text = String(Int(sender.value))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let gameViewController = segue.destination as? GameViewController,
            let sizeText = sizeLabel.text,
            let size = Int(sizeText) ,
            let numberOfBombsText = bombsLabel.text,
            let numberOfBombs = Int(numberOfBombsText) else {
            return
        }
        
        gameViewController.board = Board.create(size: size, numberOfBombs: numberOfBombs)
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
}
