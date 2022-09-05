//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

class Persister: LightningDevKit.Persister, ExtendedChannelManagerPersister {
    let fileManager = LightningFileManager()
    weak var tracker: PendingEventTracker?
    
    init(eventTracker: PendingEventTracker? = nil) {
        self.tracker = eventTracker
        super.init()
    }

    func handle_event(event: Event) {
        // Clone is necessary to avoid deallocation issues
        
        guard let tracker = tracker else { return }
        let ev = event.clone()
        
        Task {
            await tracker.addEvent(event: ev)
        }
    }
    
    override func persist_graph(network_graph: NetworkGraph) -> Result_NoneErrorZ {
        // do something to persist the graph
        let persistGraphResult = fileManager.persistGraph(graph: network_graph.write())
        
        switch persistGraphResult {
        case .success():
            return Result_NoneErrorZ.ok()
        case .failure(_):
            return Result_NoneErrorZ.err(e: LDKIOError_WriteZero)
        }
    }
    
    override func persist_manager(channel_manager: ChannelManager) -> Result_NoneErrorZ {
        let persistChannelManagerResult = fileManager.persistChannelManager(manager: channel_manager.write())
        
        switch persistChannelManagerResult {
        case .success():
            return Result_NoneErrorZ.ok()
        case .failure(_):
            return Result_NoneErrorZ.err(e: LDKIOError_WriteZero)
        }
    }
}
