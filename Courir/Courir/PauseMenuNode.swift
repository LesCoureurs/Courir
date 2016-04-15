//
//  PauseMenuNode.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/2/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

protocol PauseMenuDelegate: class {
    func pauseMenuDismissed()
    func leaveGameSelected()
}

class PauseMenuNode: SKNode {
    weak var delegate: PauseMenuDelegate?
    var overlayNode: SKShapeNode!
    let resumeNode = SKLabelNode(text: "resume")
    let leaveNode = SKLabelNode(text: "leave")
    
    override init() {
        super.init()
        initBackground()
        initResumeNode()
        initLeaveNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let position = touch.locationInNode(self)
        let touchedNode = nodeAtPoint(position)
        
        if let name = touchedNode.name {
            switch name {
                case "resume":
                    removeFromParent()
                    delegate?.pauseMenuDismissed()
                case "leave":
                    delegate?.leaveGameSelected()
                default:
                    break
            }
        }
    }
    
    private func initBackground() {
        let mainScreenBounds = UIScreen.mainScreen().bounds
        overlayNode = SKShapeNode(rect: mainScreenBounds)
        overlayNode.fillColor = SKColor.whiteColor()
        overlayNode.alpha = 0.85
        overlayNode.position = CGPoint(x: -CGRectGetMidX(mainScreenBounds),
                                       y: -CGRectGetMidY(mainScreenBounds))
        overlayNode.zPosition = 998
        overlayNode.userInteractionEnabled = false
        addChild(overlayNode)
    }
    
    private func initResumeNode() {
        resumeNode.fontName = "Baron Neue Bold 60"
        resumeNode.fontColor = blue
        resumeNode.fontSize = 40
        resumeNode.name = "resume"
        resumeNode.position = CGPoint(x: 0, y: resumeNode.frame.height)
        resumeNode.zPosition = 999
        resumeNode.userInteractionEnabled = false
        addChild(resumeNode)
    }
    
    private func initLeaveNode() {
        leaveNode.fontName = "Baron Neue Bold 60"
        leaveNode.fontColor = blue
        leaveNode.fontSize = 40
        leaveNode.name = "leave"
        leaveNode.position = CGPoint(x: 0, y: -leaveNode.frame.height)
        leaveNode.zPosition = 999
        leaveNode.userInteractionEnabled = false
        addChild(leaveNode)
    }
}