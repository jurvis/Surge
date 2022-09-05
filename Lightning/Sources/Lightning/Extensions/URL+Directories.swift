//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//
import Foundation

extension URL {
    static var channelManagerDirectory: URL {
        return documentsDirectory.appendingPathComponent("channelManager")
    }
    
    static var channelMonitorsDirectory: URL {
        return documentsDirectory.appendingPathComponent("channelMonitors", isDirectory: true)
    }
    
    static var keySeedDirectory: URL {
        return documentsDirectory.appendingPathComponent("keySeed")
    }
    
    static var networkGraphDirectory: URL {
        return documentsDirectory.appendingPathComponent("networkGraph")
    }
    
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func pathForPersistingChannelMonitor(id: String) -> URL? {
        let folderExists = (try? channelMonitorsDirectory.checkResourceIsReachable()) ?? false
        if !folderExists {
            try? FileManager.default.createDirectory(at: channelMonitorsDirectory, withIntermediateDirectories: false)
        }
        
        let fileName = "chanmon_\(id)"
        return channelMonitorsDirectory.appendingPathComponent(fileName)
    }
}
