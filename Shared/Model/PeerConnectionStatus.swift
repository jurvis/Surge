//
//  PeerConnectionStatus.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation

enum PeerConnectionStatus: Codable {
    case unconnected
    case connected(LiquidityInformation)
    case pending(LiquidityInformation)
    
    struct LiquidityInformation: Codable {
        let inboundLiqudity: UInt32
        let outboundLiqudity: UInt32
    }
}
