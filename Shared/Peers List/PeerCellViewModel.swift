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
    
    func liquidityDisplayString(connectionStatus: PeerConnectionStatus) -> String {
        switch connectionStatus {
        case .unconnected:
            return "Connect Peer"
        case .connected:
            return "Connected"
        }
    }
    
    internal init(name: String) {
        self.name = name
    }
}
