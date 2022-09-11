//
//  PeerCellViewModel.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation
import SwiftUI

class PeerCellViewModel: ObservableObject {
    let name: String
    let connectionStatus: ConnectionStatus
    
    var liquidityDisplayString: String {
        switch connectionStatus {
        case .unconnected:
            return "Open Channel"
        case .connected(let liquidityInformation):
            return "\(liquidityInformation.inboundLiqudity)/\(liquidityInformation.outboundLiqudity)"
        case .pending(_):
            return "Pending".capitalized
        }
    }
    
    struct LiquidityInformation {
        let inboundLiqudity: UInt32
        let outboundLiqudity: UInt32
    }
    
    enum ConnectionStatus {
        case unconnected
        case connected(LiquidityInformation)
        case pending(LiquidityInformation)
    }
    
    internal init(name: String, connectionStatus: PeerCellViewModel.ConnectionStatus) {
        self.name = name
        self.connectionStatus = connectionStatus
    }
}
