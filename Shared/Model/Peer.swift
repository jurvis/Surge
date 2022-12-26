//
//  Peer.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation

class Peer: ObservableObject, Codable, Equatable {
    let id: UUID
    let peerPubKey: String
    let name: String
    let connectionInformation: PeerConnectionInformation
    private var pendingFundingTransactionPubKeys: [String] = []
        
    internal init(id: UUID = UUID(), peerPubKey: String, name: String, connectionInformation: PeerConnectionInformation) {
        self.id = id
        self.peerPubKey = peerPubKey
        self.name = name
        self.connectionInformation = connectionInformation
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            self.pendingFundingTransactionPubKeys = try container.decode([String].self, forKey: .pendingFundingTransactionPubKeys)
       } catch {
           self.pendingFundingTransactionPubKeys = []
       }
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.peerPubKey = try container.decode(String.self, forKey: .peerPubKey)
        self.name = try container.decode(String.self, forKey: .name)
        self.connectionInformation = try container.decode(Peer.PeerConnectionInformation.self, forKey: .connectionInformation)
    }
    
    func addFundingTransactionPubkey(pubkey: String) {
        pendingFundingTransactionPubKeys.append(pubkey)
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

