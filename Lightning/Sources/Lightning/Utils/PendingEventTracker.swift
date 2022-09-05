//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

actor PendingEventTracker {
    private(set) var pendingManagerEvents: [Event] = []
    private(set) var continuations: [CheckedContinuation<Void, Never>] = []
    
    private func triggerContinuations(){
        let continuations = self.continuations
        self.continuations.removeAll()
        for currentContinuation in continuations {
            currentContinuation.resume()
        }
    }
    
    func addEvent(event: Event) {
        self.pendingManagerEvents.append(event)
        self.triggerContinuations()
    }
    
    func addEvents(events: [Event]) {
        self.pendingManagerEvents.append(contentsOf: events)
        self.triggerContinuations()
    }
    
    func getCount() -> Int {
        return self.pendingManagerEvents.count
    }
    
    func getEvents() -> [Event] {
        return self.pendingManagerEvents
    }
    
    func getAndClearEvents() -> [Event]{
        let events = self.pendingManagerEvents
        self.pendingManagerEvents.removeAll()
        return events
    }
    
    func awaitAddition() async {
        await withCheckedContinuation({ continuation in
            self.continuations.append(continuation)
        })
    }
}
