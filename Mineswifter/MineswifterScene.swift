import SpriteKit

let backColor = SKColor(red: 152/255.0, green: 43/255.0, blue: 89/255.0, alpha: 1.0)
let boardColor = SKColor(red: 155/255.0, green: 44/255.0, blue: 89/255.0, alpha: 1.0)
let hiddenTileColor = SKColor(red: 111/255.0, green: 32/255.0, blue: 89/255.0, alpha: 1.0)
let visibleEdgeColor = SKColor(red: 177/255.0, green: 66/255.0, blue: 97/255.0, alpha: 1.0)
let visibleTileColor = SKColor(red: 204/255.0, green: 77/255.0, blue: 97/255.0, alpha: 1.0)
let tileNumberColor = SKColor(red: 245/255.0, green: 203/255.0, blue: 198/255.0, alpha: 1.0)
let labelColor = SKColor(red: 231/255.0, green: 220/255.0, blue: 227/255.0, alpha: 1.0)

let touchHoldTimeThreshold = 0.3

let fontName = "AvenirNext-Bold"
let tileNumberFontSize: CGFloat = 20.0
let tileLabelFontSize: CGFloat = 18.0
let bombCountFontSize: CGFloat = 24.0
let tileCountFontSize: CGFloat = 24.0
let faceFontSize: CGFloat = 38.0
let labelXPadding: CGFloat = 10.0
let labelYPadding: CGFloat = 14.0

class MineswifterScene: SKScene {
    
    var gameModel = MineswifterGame()
    
    var boardNode: SKSpriteNode
    var tileNodes = [SKSpriteNode]()
    var bombCountNode: SKLabelNode
    var faceNode: SKLabelNode
    var tileCountNode: SKLabelNode
    
    var tileSpacing: Int
    var tileSize: Int
    
    var currentTouchStartTime: NSDate?
    
    override init(size: CGSize)  {
        func tileSizing(screenSize: CGSize) -> (Int, Int) {
            let tileXSpacing = screenSize.width / CGFloat(numberOfCols)
            let tileYSpacing = (screenSize.height - faceFontSize - labelYPadding) / CGFloat(numberOfRows)
            let tileSpacing = Int(tileXSpacing < tileYSpacing ? tileXSpacing : tileYSpacing)
            let tileSize = tileSpacing - 2
            return (tileSize, tileSpacing)
        }
        
        (tileSize, tileSpacing) = tileSizing(size)
        let (boardWidth, boardHeight) = (tileSpacing * numberOfCols, tileSpacing * numberOfRows)
        
        boardNode = SKSpriteNode(color: boardColor, size: CGSize(width: boardWidth, height: boardHeight))
        boardNode.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        let boardXPadding = (size.width - CGFloat(boardWidth)) / 2.0
        let boardYPadding = boardXPadding
        boardNode.position = CGPoint(x: boardXPadding, y: boardYPadding)
        
        let labelYPosition = boardNode.position.y + boardNode.size.height + labelYPadding
        bombCountNode = SKLabelNode(fontNamed: fontName)
        bombCountNode.fontSize = bombCountFontSize
        bombCountNode.fontColor = labelColor
        bombCountNode.position = CGPoint(x: size.width - labelXPadding, y: labelYPosition)
        bombCountNode.horizontalAlignmentMode = .Right
        
        faceNode = SKLabelNode(fontNamed: fontName)
        faceNode.fontSize = faceFontSize
        faceNode.position = CGPoint(x: size.width / 2, y: labelYPosition)
        
        tileCountNode = SKLabelNode(fontNamed: fontName)
        tileCountNode.fontSize = tileCountFontSize
        tileCountNode.fontColor = labelColor
        tileCountNode.position = CGPoint(x: labelYPadding, y: labelYPosition)
        tileCountNode.horizontalAlignmentMode = .Left
        
        super.init(size: size)
        self.backgroundColor = backColor
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        self.addChild(boardNode)
        self.addChild(faceNode)
        self.addChild(bombCountNode)
        self.addChild(tileCountNode)
        subscribeToNotifications()
        gameModel.startGame()
    }
    
    func subscribeToNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDrawStartingBoard:", name: "DrawStartingBoardNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleUncoverTileAt:", name: "UncoverTileAtNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSetNumberForTileAt:", name: "SetNumberForTileAtNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleFlagTileAt:", name: "FlagTileAtNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleUnflagTileAt:", name: "UnflagTileAtNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDrawBombAt:", name: "DrawBombAtNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleLostGame:", name: "LostGameNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleWonGame:", name: "WonGameNotification", object: nil)
    }
    
    func runFuncWithCoordsFromNotification(f: (Int, Int) -> (), notification: NSNotification) {
        if let rowVal: AnyObject! = notification.userInfo?["Row"] {
            if let colVal: AnyObject! = notification.userInfo?["Col"] {
                let (row, col) = (rowVal as Int, colVal as Int)
                f(row, col)
            }
        }
    }
    
    func handleDrawStartingBoard(notif: NSNotification) { drawBoard() }
    func handleUncoverTileAt(notif: NSNotification) { runFuncWithCoordsFromNotification(uncoverTileAt, notification: notif) }
    func handleFlagTileAt(notif: NSNotification) { runFuncWithCoordsFromNotification(flagTileAt, notification: notif) }
    func handleUnflagTileAt(notif: NSNotification) { runFuncWithCoordsFromNotification(unflagTileAt, notification: notif) }
    func handleDrawBombAt(notif: NSNotification) { runFuncWithCoordsFromNotification(drawBombAt, notification: notif) }
    func handleLostGame(notif: NSNotification) { loseGame() }
    func handleWonGame(notif: NSNotification) { winGame() }
    
    func handleSetNumberForTileAt(notification: NSNotification) {
        if let rowVal: AnyObject! = notification.userInfo?["Row"] {
            if let colVal: AnyObject! = notification.userInfo?["Col"] {
                if let numVal: AnyObject! = notification.userInfo?["Num"] {
                    let (row, col, num) = (rowVal as Int, colVal as Int, numVal as Int)
                    setNumberForTileAt(row, col: col, num: num)
                }
            }
        }
    }
    
    func drawBoard() {
        faceNode.text = "😀"
        updateCounts()
        addTilesToBoard()
    }
    
    func updateCounts() {
        bombCountNode.text = "💣 \(gameModel.numberOfBombsLeft)"
        tileCountNode.text = "\(gameModel.remainingTiles) ◽️"
    }
    
    func addTilesToBoard() {
        for row in 0..<numberOfRows {
            for col in 0..<numberOfCols {
                var tileNode = SKSpriteNode(color: hiddenTileColor, size: CGSize(width: tileSize, height: tileSize))
                tileNode.position = CGPoint(x: col * tileSpacing + (tileSpacing / 2), y: row * tileSpacing + (tileSpacing / 2))
                tileNodes.append(tileNode)
                boardNode.addChild(tileNode)
            }
        }
    }
    
    func uncoverTileAt(row: Int, col: Int) {
        tileNodeAt(row, col: col).color = visibleTileColor
        updateCounts()
    }
    
    func setNumberForTileAt(row: Int, col: Int, num: Int) {
        let tile = tileNodeAt(row, col: col)
        tile.color = visibleEdgeColor
        tile.addChild(numberNode(num))
    }
    
    func numberNode(num: Int) -> SKNode {
        var numberNode = SKLabelNode()
        numberNode.fontColor = tileNumberColor
        numberNode.fontName = fontName
        numberNode.fontSize = tileNumberFontSize
        numberNode.text = "\(num)"
        numberNode.position = CGPoint(x: 0, y: -tileSize / 4)
        return numberNode
    }
    
    func tileLabelNode(text: String) -> SKNode {
        var labelNode = SKLabelNode()
        labelNode.fontColor = tileNumberColor
        labelNode.fontName = fontName
        labelNode.fontSize = tileLabelFontSize
        labelNode.text = "\(text)"
        labelNode.verticalAlignmentMode = .Center
        return labelNode
    }
    
    func drawBombAt(row: Int, col: Int) {
        clearTile(row, col: col)
        tileNodeAt(row, col: col).addChild(tileLabelNode("💣"))
    }
    
    func flagTileAt(row: Int, col: Int) {
        tileNodeAt(row, col: col).addChild(tileLabelNode("❌"))
        updateCounts()
    }
    
    func unflagTileAt(row: Int, col: Int) {
        clearTile(row, col: col)
        updateCounts()
    }
    
    func clearTile(row: Int, col: Int) {
        for childNode : AnyObject in tileNodeAt(row, col: col).children {
            childNode.removeFromParent()
        }
    }
    
    func loseGame() {
        faceNode.text = "😖"
        gameModel.revealAll()
    }
    
    func winGame() {
        faceNode.text = "🎉🎈😄🎊💰"
        gameModel.revealAll()
    }
    
    func restartGame() {
        gameModel = MineswifterGame()
        tileNodes = [SKSpriteNode]()
        gameModel.startGame()
    }
    
    func tileNodeAt(row: Int, col: Int) -> SKSpriteNode {
        return tileNodes[row * numberOfCols + col]
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if touches.count == 1 {
            currentTouchStartTime = NSDate()
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if touches.count == 1 {
            var now = NSDate()
            var deltaT = now.timeIntervalSinceDate(currentTouchStartTime!)
            let touch : AnyObject! = touches.anyObject()
            let location = touch.locationInNode(self)
            let nodes = self.nodesAtPoint(location)
            for node in nodes as [SKNode] {
                if node == faceNode {
                    restartGame()
                } else if node == boardNode {
                    let boardLocation = touch.locationInNode(boardNode)
                    let (row, col) = (rowNumberAtY(boardLocation.y), colNumberAtX(boardLocation.x))
                    if row < numberOfRows && col < numberOfCols {
                        if (deltaT > touchHoldTimeThreshold) {
                            gameModel.markFlagAt(row, col: col)
                        } else {
                            gameModel.actOnTileAt(row, col: col)
                        }
                    }
                }
            }
        }
    }
    
    func rowNumberAtY(y: CGFloat) -> Int {
        return Int(y) / tileSpacing
    }
    
    func colNumberAtX(x: CGFloat) -> Int {
        return Int(x) / tileSpacing
    }
}