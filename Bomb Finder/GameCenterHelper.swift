//    MIT License
//
//    Copyright (c) [2019] [EricJLabs]
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import GameKit

class GameCenterHelper {
    private var isEnabled = false
    
    init() {
        authenticatePlayer()
    }
    
    func post(score: Score) {
        let gkScore = GKScore(leaderboardIdentifier: score.leaderBoardID)
        gkScore.value = Int64(score.time * 100)
        GKScore.report([gkScore]) { error in
            print("reported")
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func findHighScore(size: Int, numberOfBombs: Int, completion: @escaping (TimeInterval?) -> Void) {
        let leaderboardID = Score(size: size, numberOfBombs: numberOfBombs, time: 0.0).leaderBoardID
        let leaderboard = GKLeaderboard()
        leaderboard.identifier = leaderboardID
        leaderboard.loadScores { scores, error in
            if error != nil {
                completion(nil)
                return
            }
            var topUser: TimeInterval?
            if let value = leaderboard.localPlayerScore?.value {
                topUser = TimeInterval(Double(value) / 100.0)
            }
            completion(topUser)
        }

    }
    
    private func authenticatePlayer() {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] signInVC, error in
            if let signInVC = signInVC {
                UIApplication.shared.keyWindow?.rootViewController?.present(signInVC, animated: true)
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
