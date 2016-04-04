//
//  GhostStore.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class GhostStore {
    private static let ghostFileURL = NSFileManager()
        .URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        .first!.URLByAppendingPathComponent("ghost-store.data")
    private static let seedKey = "seed"
    private static let scoreKey = "score"
    private static let eventSequenceKey = "eventSequence"
    
    let seed: NSData
    let score: Int
    let eventSequence: [PlayerEvent]
    
    init(seed: NSData, score: Int, eventSequence: [PlayerEvent]) {
        self.seed = seed
        self.score = score
        self.eventSequence = eventSequence
    }
    
    convenience init?(date: NSDate) {
        guard let ghostData = GhostStore.loadGhostDictionary()[date] as? [String: NSObject],
            storedSeed = ghostData[GhostStore.seedKey] as? NSData,
            storedScore = ghostData[GhostStore.scoreKey] as? Int,
            storedEventSequence = ghostData[GhostStore.eventSequenceKey] as? [PlayerEvent] else {
            return nil
        }
        self.init(seed: storedSeed, score: storedScore, eventSequence: storedEventSequence)
    }
    
    func storeGhostData() -> Bool {
        var ghostDictionary = GhostStore.loadGhostDictionary()
        let currentDate = NSDate()
        let ghostStoreData: [String: NSObject] = [
            GhostStore.seedKey: seed,
            GhostStore.scoreKey: score,
            GhostStore.eventSequenceKey: eventSequence
        ]
        ghostDictionary[currentDate] = ghostStoreData
        return GhostStore.saveGhostDictionary(ghostDictionary)
    }
    
    private static func saveGhostDictionary(ghostDictionary: [NSDate: NSObject]) -> Bool {
        return NSKeyedArchiver.archiveRootObject(ghostDictionary,
                                                 toFile: GhostStore.ghostFileURL.path!)
    }
    
    static func removeGhostData(forDate date: NSDate) -> Bool {
        var ghostDictionary = GhostStore.loadGhostDictionary()
        ghostDictionary.removeValueForKey(date)
        return saveGhostDictionary(ghostDictionary)
    }
    
    static var storedGhostDates: [NSDate] {
        return Array(loadGhostDictionary().keys).sort {
            $0.timeIntervalSince1970 > $1.timeIntervalSince1970
        }
    }
    
    private static func loadGhostDictionary() -> [NSDate: NSObject] {
        guard let ghostDictionary = NSKeyedUnarchiver
            .unarchiveObjectWithFile(GhostStore.ghostFileURL.path!) as? [NSDate: NSObject] else {
                return [:]
        }
        return ghostDictionary
    }
}