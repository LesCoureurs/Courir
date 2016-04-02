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
    let resumeNode = SKLabelNode(text: "Resume")
    let leaveNode = SKLabelNode(text: "Leave")
    
    override init() {
        super.init()
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
    
    private func initResumeNode() {
        resumeNode.fontName = "HelveticaNeue-Bold"
        resumeNode.fontColor = UIColor.blackColor()
        resumeNode.name = "resume"
        resumeNode.position = CGPoint(x: 0, y: resumeNode.frame.height)
        resumeNode.zPosition = 999
        resumeNode.userInteractionEnabled = false
        addChild(resumeNode)
    }
    
    private func initLeaveNode() {
        leaveNode.fontName = "HelveticaNeue-Bold"
        leaveNode.fontColor = UIColor.blackColor()
        leaveNode.name = "leave"
        leaveNode.position = CGPoint(x: 0, y: -leaveNode.frame.height)
        leaveNode.zPosition = 999
        leaveNode.userInteractionEnabled = false
        addChild(leaveNode)
    }
}