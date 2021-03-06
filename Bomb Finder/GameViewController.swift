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

class GameViewController: UIViewController {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var bestTimeLabel: UILabel!
    @IBOutlet weak var bestTImeStack: UIStackView!
    
    var gameCenterHelper: GameCenterHelper?
    var board: Board?
    var firstTurn = true
    var isGameOver = false
    var updateStopwatchTimer: Timer?
    var startTime: Date?
    var previousTimeInterval: TimeInterval?
    var playerBestTime: TimeInterval?
    var paused: Bool = false {
        didSet {
            guard !isGameOver else {
                return
            }
            if paused {
                updateStopwatchTimer?.invalidate()
                previousTimeInterval = ellapsedTime
            } else {
                startTime = Date()
                startUpdateStopwatchTimer()
            }
        }
    }
    var ellapsedTime: TimeInterval {
        guard let startTime = startTime else {
            return 0.0
        }
        return Date().timeIntervalSince(startTime) + (previousTimeInterval ?? 0.0)
    }
    private weak var flagCountBarButtonItem: UIBarButtonItem?
    
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
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .always
        }
        
        guard let board = board else {
            return
        }
        gameCenterHelper?.findHighScore(size: board.width, numberOfBombs: board.numberOfBombs) { [weak self] bestTime in
            guard let bestTime = bestTime else {
                return
            }
            self?.playerBestTime = bestTime
            self?.reportPlayerBestTime()
        }
        addFlagCountBarButtonItem()
        updateFlagCount()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super .viewDidLayoutSubviews()
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func revealBoard() {
        showTime(showMillisconds: true)
        updateStopwatchTimer?.invalidate()
        updateStopwatchTimer = nil
        board?.tiles.enumerated().forEach { (index, _) in reveal(at: index, backgroundColor: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)) }
        showPlagAgain()
    }
    
    func reveal(at index: Int, backgroundColor: UIColor? = nil) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCollectionViewCell else {
            return
        }
        if !cell.coverView.isHidden, let backgroundColor = backgroundColor  {
            cell.backgroundColor = backgroundColor
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
    
    @objc func onPlayAgain() {
        guard let board = board else {
            return
        }
        isGameOver = false
        firstTurn = true
        timeLabel.text = "0"
        navigationItem.rightBarButtonItem = flagCountBarButtonItem
        hideGameOver()
        addFlagCountBarButtonItem()
        updateFlagCount()
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
                longPressAnimation(for: cell)
                if #available(iOS 10.0, *) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                updateFlagCount()
            }
        }
    }
    
    private func addFlagCountBarButtonItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        flagCountBarButtonItem = navigationItem.rightBarButtonItem

        flagCountBarButtonItem?.isEnabled = false
        flagCountBarButtonItem?.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .disabled)
    }
    
    private func updateFlagCount() {
        let numFlags = board?.tiles.reduce(0, { (totalFlags: Int, tile) in
            if tile.shown || tile.flagIcon != .flag {
                return totalFlags
            }
            return totalFlags + 1
        }) ?? 0
        flagCountBarButtonItem?.title = numFlags == 0 ? "" : "\(numFlags) 🏴‍☠️"
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
        timeLabel.text = ellapsedTimeString(ellapsedTime: ellapsedTime, showHundredths: showMillisconds)
    }

    private func ellapsedTimeString(ellapsedTime: TimeInterval, showHundredths: Bool) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second] // swift 4.1 does not cosider .nanoseconds
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .dropLeading
        
        let time = formatter.string(from: ellapsedTime) ?? ""
        
        if !showHundredths {
            return time
        }
        
        let hundredths = Int(round((ellapsedTime.truncatingRemainder(dividingBy: 1)) * 100))
        return String("\(time).\(hundredths)")
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

    private func longPressAnimation(for cell: TileCollectionViewCell) {
        let oldZPosition = cell.layer.zPosition
        cell.layer.zPosition = 100
        UIView.animate(withDuration: 0.3, animations: {
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.black.cgColor
            cell.transform =  CGAffineTransform.init(scaleX: 2.0, y: 2.0).concatenating(CGAffineTransform(translationX: 0, y: -60))
        }) { _ in
            cell.layer.borderWidth = 0
            cell.transform = CGAffineTransform.identity
            cell.layer.zPosition = oldZPosition
        }
    }
    
    private func hideGameOver() {
        gameOverLabel.isHidden = true
        gameOverLabel.text = ""
    }
    
    private func gameOver(win: Bool) {
        gameOverLabel.text = win ? "😎" : "😡"
        gameOverLabel.isHidden = false
    }
    
    private func reportScore(tapTime: Date) {
        let newTime = ellapsedTime
        reportScoreToGameCenter(timeInterval: newTime)
        if playerBestTime == nil {
            playerBestTime = newTime
        }
        if let playerBestTime = playerBestTime,
            newTime <= playerBestTime {
            self.playerBestTime = newTime
            reportPlayerBestTime()
        }
    }
    
    private func reportScoreToGameCenter(timeInterval: TimeInterval) {
        guard let board = board,
            let gameCenterHelper = gameCenterHelper else {
                return
        }
        let score = Score(size: board.width, numberOfBombs: board.numberOfBombs, time: timeInterval)
        gameCenterHelper.post(score: score)
    }
    
    @objc private func applicationWillResignActive(_ notification: NSNotification) {
        paused = true
    }
    
    @objc private func applicationDidBecomeActive(_ notification: NSNotification) {
        paused = false
    }
    
    private func reportPlayerBestTime() {
        guard let playerBestTime = playerBestTime else {
            return
        }
        bestTImeStack.isHidden = false
        bestTimeLabel.text = ellapsedTimeString(ellapsedTime: playerBestTime, showHundredths: true)
    }
    
    private func startUpdateStopwatchTimer() {
        updateStopwatchTimer?.invalidate()
        updateStopwatchTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
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
            if #available(iOS 10.0, *) {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } 
            reveal(at: indexPath.row)
            explodeCellAnimation(at: indexPath.row, updateText: "💥", updateBorderColor: .red)
            gameOver(win: false)
            revealBoard()
        case .number:
            let tapTime = Date()
            revealEmptySpaces(at: indexPath.row)
            reveal(at: indexPath.row)
            if didWin() {
                if firstTurn {
                    startTime = tapTime
                }
                gameOver(win: true)
                revealBoard()
                reportScore(tapTime: tapTime)
            }
        }
        if firstTurn && !isGameOver {
            startTime = Date()
            previousTimeInterval = nil
            startUpdateStopwatchTimer()
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
        
        let fontSize: Int
        switch bounds.width {
        case 0...14:
            fontSize = 9
        case 15...16:
            fontSize = 11
        case 17...20:
            fontSize = 14
        case 21...26:
            fontSize = 18
        default:
            fontSize = 26
        }
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        backgroundColor = .white
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
        
        let leftSafeArea: CGFloat
        let rightSafeArea: CGFloat
        if #available(iOS 11.0, *) {
            leftSafeArea = collectionView.safeAreaInsets.left
            rightSafeArea = collectionView.safeAreaInsets.right
        } else {
            leftSafeArea = 0
            rightSafeArea = 0
        }
        let marginsAndInsets = sectionInset.left + sectionInset.right + leftSafeArea + rightSafeArea + minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
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

