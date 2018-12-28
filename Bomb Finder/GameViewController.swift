//
//  GameViewController.swift
//  Bomb Finder
//
//  Created by Eric J 12/24/18.
//  Copyright © 2018 Eric J. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var playAgainButton: UIButton!
    
    var board: Board?
    var firstTurn = true
    var timer: Timer?
    var startTime: Date?
    private let formatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let columnLayout = ColumnFlowLayout(
            cellsPerRow: board?.width ?? 20,
            minimumInteritemSpacing: 1,
            minimumLineSpacing: 1,
            sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )
        
        let format = NSLocalizedString("com.ericjlabs.bombfinder.title", value: "%d Bombs", comment: "format number of bombs - 8 bombs")
        title = String(format: format, board?.numberOfBombs ?? 8)
        collectionView?.collectionViewLayout = columnLayout
        collectionView?.contentInsetAdjustmentBehavior = .always
        
        playAgainButton.isHidden = true
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 26, weight: UIFont.Weight.regular)
    }
    
    override func viewDidLayoutSubviews() {
        super .viewDidLayoutSubviews()
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func revealBoard() {
        showTime(showMillisconds: true)
        timer?.invalidate()
        timer = nil
        board?.tiles.enumerated().forEach { (index, _) in reveal(at: index) }
        showPlagAgain()
    }
    
    func reveal(at index: Int) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCollectionViewCell else {
            return
        }
        cell.coverView.isHidden = true
        cell.flagLabel.isHidden = true
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
        let adjacentIndexes = Board.findAdjacentIndexes(index: index, width: board.width, height: board.height, tiles: board.tiles)
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
    
    @IBAction func onPlayAgain(_ sender: Any) {
        guard let board = board else {
            return
        }
        firstTurn = true
        timeLabel.text = "00:00.00"
        playAgainButton.isHidden = true
        collectionView.backgroundColor = .white
        self.board = Board.create(size: board.width, numberOfBombs: board.numberOfBombs)
        collectionView.reloadData()
    }
    
     @IBAction func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began,
            let board = board else {
                return
        }
        
        let location = gestureRecognizer.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? TileCollectionViewCell {
            let tile = board.tiles[indexPath.row]
            if !tile.shown {
                cell.cycleFlagIcon(tile: tile)
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
    
    @objc func updateTimer() {
        showTime(showMillisconds: false)
    }
    
    private func showTime(showMillisconds: Bool) {
        guard let startTime = startTime else {
            return
        }
        
        let ellapsedTime = Date().timeIntervalSince(startTime)
        let ellapsedTimeRounded = Int(ellapsedTime)
        
        //let hours = ellapsedTimeRounded / 3600
        let minutes = (ellapsedTimeRounded / 60) % 60
        let seconds = ellapsedTimeRounded % 60

        if showMillisconds {
            let milliseconds = Int((ellapsedTime.truncatingRemainder(dividingBy: 1)) * 1000)
            if minutes >= 1 {
                let format = NSLocalizedString("com.ericjlabs.bombfinder.timer-min-sec-mill", value: "%d:%d.%02d", comment: "format stopwatch")
                timeLabel.text = String(format: format, minutes, seconds, milliseconds)
            } else {
                let format = NSLocalizedString("com.ericjlabs.bombfinder.timer-sec-mill", value: "%d.%02d", comment: "format stopwatch")
                timeLabel.text = String(format: format, seconds, milliseconds)
            }
        } else {
            if minutes >= 1 {
                let format = NSLocalizedString("com.ericjlabs.bombfinder.timer-min-sec-", value: "%d:%d", comment: "format stopwatch")
                timeLabel.text = String(format: format, minutes, seconds)
            } else {
                let format = NSLocalizedString("com.ericjlabs.bombfinder.timer-sec", value: "%d", comment: "format stopwatch")
                timeLabel.text = String(format: format, seconds)
            }

        }
    }
    
    private func showPlagAgain() {
        playAgainButton.isHidden = false
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
        guard board.tiles[indexPath.row].flagIcon == .none else {
            return
        }
        let tile = board.tiles[indexPath.row]
        
        switch tile.value {
        case .bomb:
            if firstTurn {
                // never allow user to lose on first guess.  Change the board and select same location
                resetBoard(indexPath: indexPath)
                return
            }
            reveal(at: indexPath.row)
            collectionView.backgroundColor = .red
            revealBoard()
        case .number:
            revealEmptySpaces(at: indexPath.row)
            reveal(at: indexPath.row)
            if didWin() {
                collectionView.backgroundColor = .green
                revealBoard()
            }
        }
        if firstTurn {
            startTime = Date()
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        }
        firstTurn = false
    }
}

class TileCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var flagLabel: UILabel!
    
    func configure(tile: Tile) {
        flagLabel.text = tile.flagIcon.icon
        flagLabel.isHidden = tile.flagIcon == .none
        coverView.isHidden = tile.shown
        switch tile.value {
        case .bomb:
            valueLabel.text = "💣"
        case let .number(number):
            valueLabel.text = number == 0 ? "" : "\(number)"
        }
    }
    
    func cycleFlagIcon(tile: Tile) {
        switch tile.flagIcon {
        case .none:
            tile.flagIcon = .flag
        case .flag:
            tile.flagIcon = .question
        case .question:
            tile.flagIcon = .none
        }
        flagLabel.isHidden = tile.flagIcon == .none
        flagLabel.text = tile.flagIcon.icon
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

extension Tile.FlagIcon {
    var icon: String {
        switch self {
        case .none:
            return ""
        case .flag:
            return "🏴‍☠️"
        case .question:
            return "🤔"
        }
    }
}

