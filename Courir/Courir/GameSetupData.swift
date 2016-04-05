//
//  GameSetupData.swift
//  Courir
//
//  Created by Karen on 5/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation
import MultipeerConnectivity

struct GameSetupData {
    private (set) var mode: GameMode
    var isMultiplayer: Bool {
        return mode == GameMode.Multiplayer || mode == GameMode.SpecialMultiplayer
    }

    private (set) var host: MCPeerID?
    var isHost: Bool {
        return host == myPeerID
    }

    private (set) var peers: [MCPeerID]
    private (set) var seed: NSData?
}
