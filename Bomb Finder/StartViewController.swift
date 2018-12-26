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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigationController?.view.isHidden = true
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
}
