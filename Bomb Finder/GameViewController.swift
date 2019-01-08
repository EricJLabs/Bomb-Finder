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
    @IBOutlet weak var playAgainButtonItem: UIBarButtonItem!
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var timeView: UIView!
    
    var gameCenterHelper: GameCenterHelper?
    var board: Board?
    var firstTurn = true
    var isGameOver = false
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
    
    private func reportScore(timeInterval: TimeInterval) {
        guard let board = board,
            let gameCenterHelper = gameCenterHelper else {
            return
        }
        let score = Score(size: board.width, numberOfBombs: board.numberOfBombs, time: timeInterval)
        gameCenterHelper.post(score: score)
    }
    
    @objc func onPlayAgain() {
        guard let board = board else {
            return
        }
        isGameOver = false
        firstTurn = true
        timeLabel.text = "00:00.00"
        navigationItem.rightBarButtonItem = nil
        hideGameOver()
        self.board = Board.create(size: board.width, numberOfBombs: board.numberOfBombs)
        collectionView.reloadData()
    }
    
     @IBAction func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began,
            !isGameOver,
            let board = board else {
                return
        }
        
        let location = gestureRecognizer.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? TileCollectionViewCell {
            let tile = board.tiles[indexPath.row]
            if !tile.shown {
                cell.cycleFlagIcon(tile: tile)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
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
        isGameOver = true
        let playAgain = NSLocalizedString("com.ericjlabs.bombfinder.play-again", value: "Play Again", comment: "Start the game again.")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: playAgain, style: .plain, target: self, action: #selector(onPlayAgain))
    }
    
    private func explodeCellAnimation(at index: Int, updateText: String, updateBorderColor: UIColor?) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCollectionViewCell else {
            return
        }
        
        cell.valueLabel.text = updateText
        let oldZPosition = cell.layer.zPosition
        cell.layer.zPosition = 100
        UIView.animate(withDuration: 0.3, animations: {
            cell.transform =  CGAffineTransform.init(scaleX: 5.0, y: 5.0)
        }) { _ in
            cell.transform = CGAffineTransform.identity
            cell.layer.zPosition = oldZPosition
            if let updateBorderColor = updateBorderColor {
                cell.layer.borderWidth = 1
                cell.layer.borderColor = updateBorderColor.cgColor
            }
        }
    }
    
    private func hideGameOver() {
        gameOverLabel.isHidden = true
        timeView.backgroundColor = .white
    }
    
    private func gameOver(win: Bool) {
        gameOverLabel.isHidden = false
        gameOverLabel.text = win ? "😎" : "😡"
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
        guard !isGameOver,
            board.tiles[indexPath.row].flagIcon == .none else {
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
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            reveal(at: indexPath.row)
            explodeCellAnimation(at: indexPath.row, updateText: "💥", updateBorderColor: .red)
            gameOver(win: false)
            revealBoard()
        case .number:
            let tapTime = Date()
            revealEmptySpaces(at: indexPath.row)
            reveal(at: indexPath.row)
            if didWin() {
                gameOver(win: true)
                revealBoard()
                if let startTime = startTime {
                    reportScore(timeInterval: tapTime.timeIntervalSince(startTime))
                }
            }
        }
        if firstTurn {
            startTime = Date()
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
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
        flagLabel.isHidden = tile.flagIcon == .none || tile.shown
        coverView.isHidden = tile.shown
        switch tile.value {
        case .bomb:
            valueLabel.text = "💣"
        case let .number(number):
            valueLabel.text = number == 0 ? "" : "\(number)"
        }
        layer.borderWidth = 0
        layer.borderColor = UIColor.white.cgColor
        
        let fontSize = bounds.width <= 26 ? 18 : 26
        flagLabel.font = flagLabel.font.withSize(CGFloat(fontSize))
        valueLabel.font = valueLabel.font.withSize(CGFloat(fontSize))
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

