//
//  Board.swift
//  Bomb Finder
//
//  Created by Eric Jenson on 12/24/18.
//  Copyright © 2018 Eric Jenson. All rights reserved.
//

struct Board {
    let width: Int
    let height: Int
    let numberOfBombs: Int
    
    let tiles: [Tile]
    
    enum AdjacentType {
        case all
        case topBottomLeftRight
    }
    
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
                let adjacentIndexes = findAdjacentIndexes(index: index, width: size, height: size, type: .all, tiles: shuffledTiles)
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
    
    static func findAdjacentIndexes(index: Int, width: Int, height: Int, type: AdjacentType, tiles: [Tile]) -> [Int] {
        let row = index / width
        let column = index % width
        var adjacentIndexes = [Int]()
        if row >= 1 {
            let rowAbove = row - 1
            if type == .all && column >= 1 {
                let columnLeft = column - 1
                let index = rowAbove * width + columnLeft
                adjacentIndexes.append(index)
            }
            let indexTop = rowAbove * width + column
            adjacentIndexes.append(indexTop)
            if type == .all && column <= width - 2 {
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
        if type == .all {
            let index = row * width + column
            adjacentIndexes.append(index)
        }
        if column <= width - 2 {
            let columnRight = column + 1
            let index = row * width + columnRight
            adjacentIndexes.append(index)
        }
        
        if row <= (height - 2) {
            let rowBelow = row + 1
            if type == .all && column >= 1 {
                let columnLeft = column - 1
                let index = rowBelow * width + columnLeft
                adjacentIndexes.append(index)
            }
            let indexBelow = rowBelow * width + column
            adjacentIndexes.append(indexBelow)
            if type == .all && column <= (width - 2) {
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
    
    let value: TileValue
    var shown = false 
    
    init(value: TileValue, shown: Bool) {
        self.value = value
        self.shown = shown
    }
}
