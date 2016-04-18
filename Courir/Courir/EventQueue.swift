//
//  EventQueue.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/16/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class EventQueue {
    /// The type of an item in the `EventQueue`
    typealias Element = (event: GameEvent, playerNumber: Int, timeStep: Int, otherData: AnyObject?)
    private var queue = [Element]()
    
    /// The head of the `EventQueue`, the `Element` in the queue with the highest priority.
    var head: Element? {
        get {
            guard count > 0 else {
                return nil
            }
            return queue[0]
        }
    }
    
    /// The number of items in the `EventQueue`.
    var count: Int {
        return queue.count
    }
    
    /// Initializes the `EventQueue` with an initial list of `Element`s.
    convenience init(initialEvents: [Element]) {
        self.init()
        queue = initialEvents
        for i in (0...(queue.count / 2 - 1)).reverse() {
            shiftDown(i)
        }
    }
    
    /// Inserts an `Element` into the `EventQueue` with the provided `event`, `playerNumber`,
    /// `timeStep` and any `otherData`.
    func insert(event: GameEvent, playerNumber: Int, timeStep: Int, otherData: AnyObject?) {
        queue.append((event, playerNumber, timeStep, otherData))
        shiftUp(count - 1)
    }
    
    /// Removes the `head` from the `EventQueue`.
    /// - Returns: The `Element` that was at the head of the queue.
    /// If the queue is empty, returns `nil`.
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
    
    /// Gets the parent index for an item at `index` in the `queue` array.
    /// `index` must be greater than `0`.
    private func getParentIndex(index: Int) -> Int {
        assert(index > 0)
        return (index + 1) / 2 - 1
    }
    
    /// Gets the child indexes for an item at `index` in the `queue` array.
    /// - Returns: A 2-tuple with left (the index of the left child) and
    /// right (the index of the right child).
    private func getChildIndexes(index: Int) -> (left: Int, right: Int) {
        let left = (index + 1) * 2 - 1
        let right = (index + 1) * 2
        return (left, right)
    }
    
    /// Shifts the `Element` found at `index` in the `queue` array up the `Element` is misplaced.
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
    
    /// Shifts the `Element` found at `index` in the `queue` array down the `Element` is misplaced.
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
    
    /// Swaps `indexA` and `indexB` in the `queue` array.
    private func swap(indexA a: Int, indexB b: Int) {
        let aData = queue[a]
        queue[a] = queue[b]
        queue[b] = aData
    }
}