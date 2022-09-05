//
//  LightningFileManager.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation

public struct LightningFileManager {
    let keysSeedPath = URL.keySeedDirectory
    let monitorPath = URL.channelMonitorsDirectory
    let managerPath = URL.channelManagerDirectory
    let networkGraphPath = URL.networkGraphDirectory
    
    public enum PersistenceError: Error {
        case cannotWrite
    }
    
    public static var hasPersistedChannelManager: Bool {
        return FileManager.default.fileExists(atPath: URL.channelManagerDirectory.absoluteString)
    }
    
    public static func clearDocumentsDirectory() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL.documentsDirectory,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  { print(error) }
    }
    
    public init() {}
    
    // MARK: - Public Read Interface
    public func getSerializedChannelManager() -> [UInt8]? {
        return readChannelManager()
    }
    
    public func getSerializedChannelMonitors() -> [[UInt8]] {
        guard let monitorUrls = monitorUrls else { return [] }
        
        return monitorUrls.compactMap { url in
            readChannelMonitor(with: url)
        }
    }
    
    public func getSerializedNetworkGraph() -> [UInt8]? {
        return readNetworkGraph()
    }
    
    public func getKeysSeed() -> [UInt8]? {
        return readKeysSeed()
    }
    
    public var hasKeySeed: Bool {
        return FileManager.default.fileExists(atPath: keysSeedPath.path)
    }
    
    public var hasChannelMaterialAndNetworkGraph: Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: managerPath.path) &&
            FileManager.default.fileExists(atPath: monitorPath.path, isDirectory: &isDir) &&
            FileManager.default.fileExists(atPath: networkGraphPath.path)
    }
    
    // MARK: - Public Write Interface
    public func persistGraph(graph: [UInt8]) -> Result<Void, PersistenceError> {
        do {
            try Data(graph).write(to: networkGraphPath)
            return .success(())
        } catch {
            return .failure(.cannotWrite)
        }
    }
    
    public func persistChannelManager(manager: [UInt8]) -> Result<Void, PersistenceError> {
        do {
            try Data(manager).write(to: managerPath)
            return .success(())
        } catch {
            return .failure(.cannotWrite)
        }
    }
    
    public func persistKeySeed(keySeed: [UInt8]) -> Result<Void, PersistenceError> {
        do {
            try Data(keySeed).write(to: keysSeedPath)
            return .success(())
        } catch {
            return .failure(.cannotWrite)
        }
    }
    
    // MARK: - Private Read Functions
    private func readKeysSeed() -> [UInt8]? {
        do {
            let data = try Data(contentsOf: keysSeedPath)
            return Array(data)
        } catch {
            return nil
        }
    }
    
    private func readChannelManager() -> [UInt8]? {
        do {
            let data = try Data(contentsOf: managerPath)
            return Array(data)
        } catch {
            return nil
        }
    }
    
    private func readChannelMonitor(with channelURL: URL) -> [UInt8]? {
        do {
            let data = try Data(contentsOf: channelURL)
            if let monitor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? ChannelMonitor {
                return monitor.monitorBytes
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    private func readNetworkGraph() -> [UInt8]? {
        do {
            let data = try Data(contentsOf: networkGraphPath)
            return Array(data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Write Functions
    
    
    
    // MARK: - Computed Properties
    private var monitorUrls: [URL]? {
        do {
            let items = try FileManager.default.contentsOfDirectory(at: URL.channelMonitorsDirectory, includingPropertiesForKeys: nil)
            return items
        } catch {
            return nil
        }
    }
}
