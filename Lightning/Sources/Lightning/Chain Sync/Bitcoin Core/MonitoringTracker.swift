//
//  File.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation

actor MonitoringTracker {
    private(set) var isPreloaded = false
    private(set) var isTracking = false

    func preload() -> Bool {
        let wasPreloaded = self.isPreloaded
        self.isPreloaded = true
        return wasPreloaded
    }

    func startTracking() -> Bool {
        let wasTracking = self.isTracking
        self.isTracking = true
        return wasTracking
    }
}
