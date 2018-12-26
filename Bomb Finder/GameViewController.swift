//
//  GameViewController.swift
//  Bomb Finder
//
//  Created by Eric Jenson on 12/24/18.
//  Copyright © 2018 Eric Jenson. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    var board: Board?
    var firstTurn = true
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let columnLayout = ColumnFlowLayout(
            cellsPerRow: board?.width ?? 20,
            minimumInteritemSpacing: 1,
            minimumLineSpacing: 1,
            sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )
        
        let format = NSLocalizedString("com.ericjlabs.bombfinder", value: "%d Bombs", comment: "format number of bombs - 8 bombs")
        navigationController?.title = String(format: format, board?.numberOfBombs ?? 8)
        collectionView?.collectionViewLayout = columnLayout
        collectionView?.contentInsetAdjustmentBehavior = .always
    }
    
    func revealBoard() {
        board?.tiles.enumerated().forEach { (index, _) in reveal(at: index) }
    }
    
    func reveal(at index: Int) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCollectionViewCell else {
            return
        }
        cell.coverView.isHidden = true
        board?.tiles[index].shown = true
    }
    
    func revealEmptySpaces(at index: Int) {
        guard let board = board else {
            return
        }
        guard !board.tiles[index].shown, case let .number(number) = board.tiles[index].value else {
            return
        }
        reveal(at: index)
        if number != 0 {
            return
        }
        let adjacentIndexes = Board.findAdjacentIndexes(index: index, width: board.width, height: board.height, type: .all, tiles: board.tiles)
        adjacentIndexes.forEach { adjacentIndex in
            revealEmptySpaces(at: adjacentIndex)
        }
    }
    
    func didWin() -> Bool {
        guard let board = board else {
            return false
        }
        return board.tiles.first { tile in
            switch tile.value {
            case .bomb:
                return false
            case .number:
                return !tile.shown
            }
        } == nil
    }
    
    @IBAction func onLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended,
            let board = board else {
                return
        }
        
        let location = gesture.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? TileCollectionViewCell {
            let tile = board.tiles[indexPath.row]
            if !tile.shown {
                cell.showFlag()
            }
        }
    }
    
    func resetBoard(indexPath: IndexPath) {
        guard let board = board else {
            return
        }
        self.board = Board.create(size: board.width, numberOfBombs: board.numberOfBombs)
        collectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let collectionView = self?.collectionView else {
                return
            }
            self?.collectionView(collectionView, didSelectItemAt: indexPath)
        }
    }
}

extension GameViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let board = board else {
            preconditionFailure()
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCollectionViewCell", for: indexPath) as? TileCollectionViewCell else {
            preconditionFailure()
        }
        cell.configure(tile: board.tiles[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section == 0,
            let board = board else {
            return 0
        }
        
        return board.tiles.count
    }
}

extension GameViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let board = board else {
            assertionFailure()
            return
        }
        let tile = board.tiles[indexPath.row]
        
        switch tile.value {
        case .bomb:
            if firstTurn {
                resetBoard(indexPath: indexPath)
                return
            }
            reveal(at: indexPath.row)
            collectionView.backgroundColor = .red
            revealBoard()
        case let .number(number):
            revealEmptySpaces(at: indexPath.row)
            reveal(at: indexPath.row)
            if didWin() {
                collectionView.backgroundColor = .green
                revealBoard()
            }
        }
        firstTurn = false
    }
}

class TileCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var flagLabel: UILabel!
    
    func configure(tile: Tile) {
        switch tile.value {
        case .bomb:
            valueLabel.text = "💣"
        case let .number(number):
            valueLabel.text = number == 0 ? "" : "\(number)"
        }
    }
    
    func showFlag() {
        flagLabel.isHidden = false
    }
}

class ColumnFlowLayout: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else {
            return
        }
        
        let marginsAndInsets = sectionInset.left + sectionInset.right + collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right + minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
        itemSize = CGSize(width: itemWidth, height: itemWidth)
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}
