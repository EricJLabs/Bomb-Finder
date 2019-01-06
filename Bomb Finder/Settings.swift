//
//  Settings.swift
//  Bomb Finder
//
//  Created by Eric J on 12/29/18.
//  Copyright © 2018 Eric J. All rights reserved.
//

import UIKit

struct Settings {
    
    static var shared = Settings()
    
    private init() {}
    
    var level: Level {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.level.rawValue)
        }
        get {
            let value = UserDefaults.standard.integer(forKey: Keys.level.rawValue)
            return Level.init(rawValue: value) ?? .easy
        }
    }
    
    var size: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.size.rawValue)
        }
        get {
            let value = UserDefaults.standard.integer(forKey: Keys.size.rawValue)
            return value == 0 ? 9 : value
        }
    }
    
    var hasPromptedForGameCenter: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasPromptedForGameCenter.rawValue)
        }
        get {
            return UserDefaults.standard.bool(forKey: Keys.hasPromptedForGameCenter.rawValue)
        }
    }
    
    private enum Keys: String {
        case hasPromptedForGameCenter = "hasPromptedForGameCenter"
        case level = "level"
        case size = "size"
    }
}

enum Level: Int {
    case easy = 0
    case intermediate = 1
    case hard = 2
    private enum Keys: String {
        case hasPromptedForGameCenter = "hasPromptedForGameCenter"
    }
}
