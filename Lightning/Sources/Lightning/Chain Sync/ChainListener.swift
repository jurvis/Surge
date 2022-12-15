//
//  ChainListener.swift
//  https://docs.rs/lightning/0.0.112/lightning/chain/trait.Listen.html
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import LightningDevKit

class ChainListener {
    private let channelManager: ChannelManager
    private let chainMonitor: ChainMonitor

    init(channelManager: ChannelManager, chainMonitor: ChainMonitor) {
        self.channelManager = channelManager
        self.chainMonitor = chainMonitor
    }
    
    func blockConnected(block: [UInt8], height: UInt32) {
        print("block connected at height \(height): \(block)")
        self.channelManager.as_Listen().block_connected(block: block, height: height)
        self.chainMonitor.as_Listen().block_connected(block: block, height: height)
    }

    func blockDisconnected(header: [UInt8]?, height: UInt32) {
        print("block disconnected from height \(height): \(header)")
        self.channelManager.as_Listen().block_disconnected(header: header, height: height)
        self.chainMonitor.as_Listen().block_disconnected(header: header, height: height)
    }
}
