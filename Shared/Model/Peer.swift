//
//  Peer.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation

struct Peer: Identifiable, Codable {
    let id: UUID
    let peerPubKey: String
    let name: String
    let connectionStatus: PeerConnectionStatus
    
    internal init(id: UUID = UUID(), peerPubKey: String, name: String, connectionStatus: PeerConnectionStatus) {
        self.id = id
        self.peerPubKey = peerPubKey
        self.name = name
        self.connectionStatus = connectionStatus
    }
}
