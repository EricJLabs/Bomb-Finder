//
//  GameCenterHelper.swift
//  Bomb Finder
//
//  Created by Eric J on 12/29/18.
//  Copyright © 2018 Eric J. All rights reserved.
//

import GameKit

class GameCenterHelper {
    private var isEnabled = false
    
    init() {
        authenticatePlayer()
    }
    
    func post(score: Score) {
        let gkScore = GKScore(leaderboardIdentifier: score.leaderBoardID)
        gkScore.value = Int64(score.time)
        GKScore.report([gkScore]) { error in
            print("reported")
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func findHighScore(leaderBoardID: String) -> Score? {
        guard let score = GKScore(leaderboardIdentifier: leaderBoardID) as? Score else {
            return nil
        }
        
    }
    
    private func authenticatePlayer() {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] signInVC, error in
            if let signInVC = signInVC {
                signInVC.present(signInVC, animated: true)
            }
            if player.isAuthenticated {
                self?.isEnabled = true
                
                player.loadDefaultLeaderboardIdentifier()
            }
        }
        
    }
}

struct Score {
    let size: Int
    let numberOfBombs: Int
    let time: TimeInterval

    var leaderBoardID: String {
        return String("com.ericjlabs.bomb_finder_\(size)_\(numberOfBombs)")
    }
}
