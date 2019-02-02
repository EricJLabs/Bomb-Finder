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
