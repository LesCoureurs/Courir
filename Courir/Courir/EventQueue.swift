//
//  EventQueue.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/16/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class EventQueue {
    typealias Element = (event: GameEvent, playerNumber: Int, timeStep: Int, otherData: AnyObject?)
    private var queue = [Element]()
    
    var head: Element? {
        get {
            guard count > 0 else {
                return nil
            }
            return queue[0]
        }
    }
    
    var count: Int {
        return queue.count
    }
    
    convenience init(initialEvents: [Element]) {
        self.init()
        queue = initialEvents
        for i in (0...(queue.count / 2 - 1)).reverse() {
            shiftDown(i)
        }
    }
    
    func insert(event: GameEvent, playerNumber: Int, timeStep: Int, otherData: AnyObject?) {
        queue.append((event, playerNumber, timeStep, otherData))
        shiftUp(count - 1)
    }
    
    func removeHead() -> Element? {
        guard count > 0 else {
            return nil
        }
        guard count != 1 else {
            return queue.removeLast()
        }
        let head = self.head!
        swap(indexA: 0, indexB: count - 1)
        queue.removeLast()
        shiftDown(0)
        return head
    }
    
    private func getParentIndex(index: Int) -> Int {
        assert(index > 0)
        return (index + 1) / 2 - 1
    }
    
    private func getChildIndexes(index: Int) -> (left: Int, right: Int) {
        let left = (index + 1) * 2 - 1
        let right = (index + 1) * 2
        return (left, right)
    }
    
    private func shiftUp(index: Int) {
        guard index > 0 else {
            return
        }
        let parentIndex = getParentIndex(index)
        let currentVal = queue[index].timeStep
        let parentVal = queue[parentIndex].timeStep
        if currentVal < parentVal {
            swap(indexA: index, indexB: parentIndex)
            shiftUp(parentIndex)
        }
    }
    
    private func shiftDown(index: Int) {
        let childIndexes = getChildIndexes(index)
        let currentVal = queue[index].timeStep
        let leftVal = childIndexes.left < count ? queue[childIndexes.left].timeStep : Int.max
        let rightVal = childIndexes.right < count ? queue[childIndexes.right].timeStep : Int.max
        
        let indexToSwap: Int
        if currentVal > leftVal && currentVal > rightVal {
            indexToSwap = leftVal < rightVal ? childIndexes.left : childIndexes.right
        } else if currentVal > leftVal {
            indexToSwap = childIndexes.left
        } else if currentVal > rightVal {
            indexToSwap = childIndexes.right
        } else {
            return
        }
        
        swap(indexA: index, indexB: indexToSwap)
        shiftDown(indexToSwap)
    }
    
    private func swap(indexA a: Int, indexB b: Int) {
        let aData = queue[a]
        queue[a] = queue[b]
        queue[b] = aData
    }
}