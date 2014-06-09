import UIKit
import SpriteKit

class MineswifterViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = self.view as SKView
        let scene = MineswifterScene(size: view.frame.size)
        scene.scaleMode = SKSceneScaleMode.AspectFit
        view.presentScene(scene)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.toRaw())
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
}