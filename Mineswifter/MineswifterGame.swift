let numberOfRows = 13
let numberOfCols = 9
let numberOfBombs = 20

enum Tile {
    case Hidden(Bool, Bool) // hasBomb, isFlagged
    case Visible
}

import Foundation
func randomIntUpTo(n: Int) -> Int {
    return Int(arc4random_uniform(UInt32(n)))
}

class MineswifterGame {
    
    var numberOfBombsLeft = numberOfBombs
    var remainingTiles = numberOfRows * numberOfCols - numberOfBombs
    var tiles = Array(count: numberOfRows * numberOfCols, repeatedValue: Tile.Hidden(false, false))
    
    init() {}
    
    func startGame() {
        setupTiles()
    }
    
    func setupTiles() {
        for i in 0..<numberOfBombs {
            let row = randomIntUpTo(numberOfRows)
            let col = randomIntUpTo(numberOfCols)
            if !tileHasBomb(row, col: col) {
                setTileAt(Tile.Hidden(true, false), row: row, col: col)
            }
        }
        notifyView("DrawStartingBoardNotification")
    }
    
    func setTileAt(tile: Tile, row: Int, col: Int) {
        tiles[(row * numberOfCols) + col] = tile
    }
    
    func tileAt(row: Int, col: Int) -> Tile {
        return tiles[(row * numberOfCols) + col]
    }
    
    func tileHasBomb(row: Int, col: Int) -> Bool {
        switch tileAt(row, col: col) {
        case let .Hidden(hasBomb, _):
            return hasBomb
        case .Visible:
            return false
        }
    }
    
    func actOnTileAt(row: Int, col: Int) {
        switch tileAt(row, col: col) {
        case let .Hidden(hasBomb, isFlagged):
            if isFlagged {
                return ()
            } else if hasBomb {
                notifyView("LostGameNotification")
            } else {
                uncoverTileAt(row, col: col)
                if remainingTiles == 0 {
                    notifyView("WonGameNotification")
                }
            }
        case .Visible:
            return ()
        }
    }
    
    func uncoverTileAt(row: Int, col: Int) {
        remainingTiles--
        notifyView("UncoverTileAtNotification", info: ["Row": row, "Col": col])
        var numAdjacentBombs = 0
        performFuncOnCellsAdjacentTo({ r, c in if self.tileHasBomb(r, col: c) { numAdjacentBombs++ } }, row: row, col: col)
        setTileAt(Tile.Visible, row: row, col: col)
        if numAdjacentBombs > 0 {
            notifyView("SetNumberForTileAtNotification", info: ["Row": row, "Col": col, "Num": numAdjacentBombs])
        } else {
            performFuncOnCellsAdjacentTo(uncoverIfHiddenAt, row: row, col: col)
        }
    }
    
    func performFuncOnCellsAdjacentTo(gridFunc: (Int, Int) -> (), row: Int, col: Int) {
        func boundedGridFunc(r: Int, c: Int) {
            if r >= 0 && r < numberOfRows && c >= 0 && c < numberOfCols {
                return gridFunc(r, c)
            }
        }
        boundedGridFunc(row - 1, col - 1)
        boundedGridFunc(row - 1, col)
        boundedGridFunc(row - 1, col + 1)
        boundedGridFunc(row, col - 1)
        boundedGridFunc(row, col + 1)
        boundedGridFunc(row + 1, col - 1)
        boundedGridFunc(row + 1, col)
        boundedGridFunc(row + 1, col + 1)
    }
    
    func uncoverIfHiddenAt(row: Int, col: Int) {
        switch tileAt(row, col: col) {
        case Tile.Hidden(_, _):
            return uncoverTileAt(row, col: col)
        case Tile.Visible:
            return ()
        }
    }
    
    func markFlagAt(row: Int, col: Int) {
        switch tileAt(row, col: col) {
        case let .Hidden(hasBomb, isFlagged):
            if isFlagged {
                numberOfBombsLeft++
                notifyView("UnflagTileAtNotification", info: ["Row": row, "Col": col])
                setTileAt(Tile.Hidden(hasBomb, false), row: row, col: col)
            } else {
                numberOfBombsLeft--
                notifyView("FlagTileAtNotification", info: ["Row": row, "Col": col])
                setTileAt(Tile.Hidden(hasBomb, true), row: row, col: col)
            }
        case .Visible:
            return ()
        }
    }
    
    func revealAll() {
        for row in 0..<numberOfRows {
            for col in 0..<numberOfCols {
                if tileHasBomb(row, col: col) {
                    notifyView("DrawBombAtNotification", info: ["Row": row, "Col": col])
                }
            }
        }
    }
    
    func notifyView(name: String, info: Dictionary<String, Int>? = nil) {
        if let userInfo = info {
            NSNotificationCenter.defaultCenter().postNotificationName(name, object: nil, userInfo: userInfo)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName(name, object: nil)
        }
    }
    
}