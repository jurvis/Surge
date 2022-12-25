//
//  Peer.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation

struct Peer: Codable, Equatable {
    let id: UUID
    let peerPubKey: String
    let name: String
    let connectionInformation: PeerConnectionInformation
        
    internal init(id: UUID = UUID(), peerPubKey: String, name: String, connectionInformation: PeerConnectionInformation) {
        self.id = id
        self.peerPubKey = peerPubKey
        self.name = name
        self.connectionInformation = connectionInformation
    }
}

// MARK: Helper Models
extension Peer {
    struct PeerConnectionInformation: Codable {
        let hostname: String
        let port: UInt16
    }
}

extension Peer: Identifiable, Hashable {
    var identifier: String {
        return peerPubKey
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    public static func == (lhs: Peer, rhs: Peer) -> Bool {
        return lhs.peerPubKey == rhs.peerPubKey
    }
}

