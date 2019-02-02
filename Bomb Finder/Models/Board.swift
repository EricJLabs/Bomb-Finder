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

struct Board {
    let width: Int
    let height: Int
    let numberOfBombs: Int
    
    let tiles: [Tile]
    
    static func create(size: Int, numberOfBombs: Int) -> Board {
        let remainingTiles = (size * size) - numberOfBombs
        let notBombArray = Array(1...remainingTiles).map { _ in Tile(value: .number(0), shown: false)}
        let bombArray = Array(1...numberOfBombs).map { _ in Tile(value: .bomb, shown: false)}
        let shuffledTiles = (bombArray + notBombArray).shuffled()
        let tiles = shuffledTiles.enumerated().map { arg -> Tile in
            let (index, tile) = arg
            switch tile.value {
            case .bomb:
                return tile
            case .number:
                let adjacentIndexes = findAdjacentIndexes(index: index, width: size, height: size, tiles: shuffledTiles)
                    .filter { index in
                        switch shuffledTiles[index].value {
                        case .bomb:
                            return true
                        case .number:
                            return false
                        }
                }
                return Tile(value: Tile.TileValue.number(adjacentIndexes.count), shown: false)
            }
        }
        
        return Board(width: size, height: size, numberOfBombs: numberOfBombs, tiles: tiles)
    }
    
    static func findAdjacentIndexes(index: Int, width: Int, height: Int, tiles: [Tile]) -> [Int] {
        let row = index / width
        let column = index % width
        var adjacentIndexes = [Int]()
        if row >= 1 {
            let rowAbove = row - 1
            if column >= 1 {
                let columnLeft = column - 1
                let index = rowAbove * width + columnLeft
                adjacentIndexes.append(index)
            }
            let indexTop = rowAbove * width + column
            adjacentIndexes.append(indexTop)
            if column <= width - 2 {
                let columnRight = column + 1
                let index = rowAbove * width + columnRight
                adjacentIndexes.append(index)
            }
        }
        
        if  column >= 1 {
            let columnLeft = column - 1
            let index = row * width + columnLeft
            adjacentIndexes.append(index)
        }
        let index = row * width + column
        adjacentIndexes.append(index)
        if column <= width - 2 {
            let columnRight = column + 1
            let index = row * width + columnRight
            adjacentIndexes.append(index)
        }
        
        if row <= (height - 2) {
            let rowBelow = row + 1
            if column >= 1 {
                let columnLeft = column - 1
                let index = rowBelow * width + columnLeft
                adjacentIndexes.append(index)
            }
            let indexBelow = rowBelow * width + column
            adjacentIndexes.append(indexBelow)
            if column <= (width - 2) {
                let columnRight = column + 1
                let index = rowBelow * width + columnRight
                adjacentIndexes.append(index)
            }
        }
        
        return adjacentIndexes
    }
}

class Tile {
    enum TileValue {
        case bomb
        case number(Int)
    }
    
    enum FlagIcon {
        case none
        case flag
        case question
    }

    let value: TileValue
    var shown = false 
    var flagIcon = FlagIcon.none

    init(value: TileValue, shown: Bool) {
        self.value = value
        self.shown = shown
    }
}
