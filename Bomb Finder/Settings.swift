//
//  Settings.swift
//  Bomb Finder
//
//  Created by Eric J on 1/6/19.
//  Copyright © 2019 Eric J. All rights reserved.
//

class Settings {
    static let shared = Settings()
    
    private init() {
    }
    
    let level: Level {
        get {
            return
        }
        set {
            
        }
    }
    
}

enum Level: Int {
    case easy = 0
    case intermediate = 1
    case hard = 2
}
