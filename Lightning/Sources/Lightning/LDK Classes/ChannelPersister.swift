//
//  ChannelPersister.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import LightningDevKit

class ChannelPersister: Persist {
    override func persist_new_channel(channel_id: Bindings.OutPoint, data: Bindings.ChannelMonitor, update_id: Bindings.MonitorUpdateId) -> Bindings.Result_NoneChannelMonitorUpdateErrZ {
        let idBytes: [UInt8] = channel_id.write()
        let monitorBytes: [UInt8] = data.write()

        let channelMonitor = ChannelMonitor(idBytes: idBytes, monitorBytes: monitorBytes)

        do {
           try persistChannelMonitor(channelMonitor, for: channel_id.write().toHexString())
        } catch {
           return Result_NoneChannelMonitorUpdateErrZ.ok()
        }

        return Result_NoneChannelMonitorUpdateErrZ.ok()
    }
    
    override func update_persisted_channel(channel_id: Bindings.OutPoint, update: Bindings.ChannelMonitorUpdate, data: Bindings.ChannelMonitor, update_id: Bindings.MonitorUpdateId) -> Bindings.Result_NoneChannelMonitorUpdateErrZ {
        let idBytes: [UInt8] = channel_id.write()
        let monitorBytes: [UInt8] = data.write()

        let channelMonitor = ChannelMonitor(idBytes: idBytes, monitorBytes: monitorBytes)
        do {
           try persistChannelMonitor(channelMonitor, for: idBytes.toHexString())
        } catch {
           return Result_NoneChannelMonitorUpdateErrZ.ok()
        }

        return Result_NoneChannelMonitorUpdateErrZ.ok()
    }
    
    func persistChannelMonitor(_ channelMonitor: ChannelMonitor, for channelId: String) throws {
        guard let pathToPersist = URL.pathForPersistingChannelMonitor(id: channelId) else {
            throw ChannelPersisterError.invalidPath
        }
        
        do {
           let data = try NSKeyedArchiver.archivedData(
               withRootObject: channelMonitor,
               requiringSecureCoding: false
           )
           try data.write(to: pathToPersist)
        } catch {
           throw error
        }
    }
}

// MARK: Errors
extension ChannelPersister {
    public enum ChannelPersisterError: Error {
        case invalidPath
    }
}
