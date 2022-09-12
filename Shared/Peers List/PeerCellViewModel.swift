//
//  PeerCellViewModel.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation
import SwiftUI

class PeerCellViewModel: ObservableObject {
    @Published var connectionStatus: PeerConnectionStatus
    let name: String
    
    var liquidityDisplayString: String {
        switch connectionStatus {
        case .unconnected:
            return "Connect Peer"
        case .connected:
            return "Connected"
        }
    }
    
    internal init(name: String, connectionStatus: PeerConnectionStatus) {
        self.connectionStatus = connectionStatus
        self.name = name
    }
}
