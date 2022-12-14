//
//  File.swift
//  Surge
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import Combine
import Lightning
import CryptoSwift

class LightningNodeService {
    private let instance: Node
    private let fileManager = LightningFileManager()
    
    private var started = false
    private var cancellabels = Set<AnyCancellable>()
    
    // A singleton is appropriate for this situation, considering we should really only have one Lightning node running at any given time
    class var shared: LightningNodeService {
        struct Singleton {
            static let instance = LightningNodeService(
                connectionType: .regtest(BitcoinCoreRpcConfig(username: "polaruser", password: "polarpass", port: 18443, host: "localhost"))
            )
        }
        return Singleton.instance
    }
    
    init(connectionType: ConnectionType) {
        switch connectionType {
        case .regtest(let config):
            instance = Node(type: .regtest(config))
        case .testnet:
            fatalError("Not implemented!")
        }
    }
    
    func start() async throws {
        guard !started else { throw ServiceError.alreadyRunning }
        
        // FIXME: Make this data write await-able
        if !fileManager.hasKeySeed {
            generateKeySeed()
        }
        
        guard let _ = fileManager.getKeysSeed() else { throw ServiceError.keySeedNotFound }
        
        do {
            try await instance.start()
        } catch {
            throw error
        }
    }
    
    func connectPeer(_ peer: Peer) async throws {
        try await instance.connectPeer(pubKey: peer.peerPubKey, hostname: peer.connectionInformation.hostname, port: peer.connectionInformation.port)
    }
}

// MARK: Helpers
extension LightningNodeService {
    func generateKeySeed() {
        let seed = AES.randomIV(32)
        _ = fileManager.persistKeySeed(keySeed: seed)
    }
}

// MARK: Publishers
extension LightningNodeService {
    var activePeersPublisher: AnyPublisher<[String], Never> {
        return instance.connectedPeers
    }
}

// MARK: Errors
extension LightningNodeService {
    public enum ServiceError: Error {
        case alreadyRunning
        case invalidHash
        case cannotOpenChannel
        case keySeedNotFound
    }
}
