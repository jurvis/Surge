//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation

public enum NodeError: Error {
    case connectPeer
    case noChannelManager
    case keyInterfaceFailure
    case keySeedNotFound
    case alreadyRunning
    case noChainManager
    case channelMaterialNotFound
    
    public enum Channels: Error {
        case misuse
        case value
        case unavailable
        case feeTooHigh
        case incompatibleShutdown
        case unknown
        case channelManagerNotFound
        case fundingFailure
    }
    
    public enum Invoice: Error {
        case notFound
        case invoicePaymentFailed
    }
}
