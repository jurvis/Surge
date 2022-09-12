//
//  Node.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import Combine
import LightningDevKit

public class Node {
    let fileManager = LightningFileManager()
    let pendingEventTracker = PendingEventTracker()
    let connectionType: ConnectionType
    
    var keysManager: KeysManager?
    var rpcInterface: RpcChainManager?
    var broadcaster: Broadcaster?
    var channelManagerConstructor: ChannelManagerConstructor?
    var channelManager: ChannelManager?
    var persister: Persister?
    var peerManager: PeerManager?
    var tcpPeerHandler: TCPPeerHandler?
    
    var blockchainListener: ChainListener?
    
    var cancellables = Set<AnyCancellable>()
    
    // We declare this here because `ChannelManagerConstructor` and `ChainMonitor` will share a reference to them
    let logger = Logger()
    let feeEstimator = FeeEstimator()
    let filter = Filter()
    
    public init(type: ConnectionType) {
        self.connectionType = type
    }
    
    public func start() async throws {
        guard let keySeed = fileManager.getKeysSeed() else { throw NodeError.keySeedNotFound }
        
        let timestampInSeconds = UInt64(Date().timeIntervalSince1970)
        let timestampInNanoseconds = UInt32(truncating: NSNumber(value: timestampInSeconds * 1000 * 1000))
        
        // Setup KeysManager
        keysManager = KeysManager(seed: keySeed, starting_time_secs: timestampInSeconds, starting_time_nanos: timestampInNanoseconds)
        
        // grab keyInterface, we will need it later to construct a ChannelManager
        guard let keysInterface = keysManager?.as_KeysInterface() else {
            throw NodeError.keyInterfaceFailure
        }
        
        switch connectionType {
        case .regtest(let bitcoinCoreRpcConfig):
            rpcInterface = try BitcoinCoreChainManager(
                rpcProtocol: .http,
                host: bitcoinCoreRpcConfig.host,
                port: bitcoinCoreRpcConfig.port,
                username: bitcoinCoreRpcConfig.username,
                password: bitcoinCoreRpcConfig.password
            )
        case .testnet:
            fatalError("Not implemented!")
        }
        
        guard let rpcInterface = rpcInterface else {
            throw NodeError.noChainManager
        }
        
        broadcaster = Broadcaster(rpcInterface: rpcInterface)
        
        let chainMonitor = ChainMonitor(
            chain_source: Option_FilterZ(value: filter),
            broadcaster: broadcaster!, // Force unwrap since we definitely set it in L61
            logger: logger,
            feeest: feeEstimator,
            persister: ChannelPersister()
        )
        
        if case .regtest = connectionType,
           let rpcInterface = rpcInterface as? BitcoinCoreChainManager {
            try await rpcInterface.preloadMonitor(anchorHeight: .chaintip)
        }
        
        
        if fileManager.hasChannelMaterialAndNetworkGraph {
            channelManagerConstructor = try await loadChannelManagerConstructor(keysInterface: keysInterface, chainMonitor: chainMonitor)
        } else {
            // Create new channel material and network graph
            let chaintipHeight = try await rpcInterface.getChaintipHeight()
            let chaintipHash = try await rpcInterface.getChaintipHash()
            let reversedChaintipHash = [UInt8](chaintipHash.reversed())
            
            channelManagerConstructor = try await initializeChannelMaterialAndNetworkGraph(
                currentTipHash: reversedChaintipHash,
                currentTipHeight: chaintipHeight,
                keysInterface: keysInterface,
                chainMonitor: chainMonitor,
                broadcaster: broadcaster! // Force unwrap since we definitely set it in L61
            )
        }
        
        channelManager = channelManagerConstructor!.channelManager // we just set ChannelManagerConstructor above
        peerManager = channelManagerConstructor!.peerManager
        tcpPeerHandler = channelManagerConstructor!.getTCPPeerHandler()
        
        persister = Persister(eventTracker: pendingEventTracker)
        guard let channelManager = channelManager else {
            throw NodeError.noChannelManager
        }
        
        blockchainListener = ChainListener(channelManager: channelManager, chainMonitor: chainMonitor)
        let isMonitoring = await rpcInterface.isMonitoring()
        
        if !isMonitoring {
            try subscribeToChainPublisher()
        } else {
            print("Surge: Monitor already running")
        }
     
        print("Surge: LDK is Running with key: \(channelManager.get_our_node_id().toHexString())")
    }
    
    public func connectPeer(pubKey: String, hostname: String, port: UInt16) async throws {
        print("Surge: Connecting to peer \(pubKey)")
        guard let _ = peerManager else {
            throw NodeError.connectPeer
        }
        
        guard let _ = tcpPeerHandler?.connect(address: hostname, port: port, theirNodeId: pubKey.toByteArray()) else {
            throw NodeError.connectPeer
        }
        
        print("Surge: peer connected \(pubKey)")
    }
}

// MARK: Publishers
extension Node {
    public var connectedPeers: AnyPublisher<[String], Never> {
        Timer.publish(every: 5, on: .main, in: .default)
            .autoconnect()
            .filter { [weak self] _ in self?.peerManager != nil }
            .flatMap { [weak self] _ -> AnyPublisher<[String], Never> in
                let peers = self?.peerManager!.get_peer_node_ids().compactMap { $0.toHexString() }
                
                return Just(peers ?? []).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}


// MARK: Helpers
extension Node {
    private func subscribeToChainPublisher() throws {
        guard let rpcInterface = rpcInterface else {
            throw NodeError.noChainManager
        }
        
        rpcInterface.blockchainMonitorPublisher
            .sink(receiveCompletion: { error in
                print("CasaLDK: Error subscribing to blockchain monitor")
            }, receiveValue: { [unowned self] _ in
                if let channelManagerConstructor = channelManagerConstructor,
                    let networkGraph = channelManagerConstructor.net_graph,
                    let persister = persister {
                    
                    let scoringParams = ProbabilisticScoringParameters()
                    let probabalisticScorer = ProbabilisticScorer(params: scoringParams, network_graph: networkGraph, logger: logger)
                    let score = probabalisticScorer.as_Score()
                    
                    channelManagerConstructor.chain_sync_completed(persister: persister, scorer: MultiThreadedLockableScore(score: score))
                    
                    print("Reconciled Chain Tip")
                } else {
                    print("CasaLDK: Chain Tip Reconcilation Failed. ChannelManagerConstructor does not have a network graph!")
                }
            })
            .store(in: &cancellables)
    }
    
    private func loadChannelManagerConstructor(keysInterface: KeysInterface, chainMonitor: ChainMonitor) async throws -> ChannelManagerConstructor {
        if let channelManager = fileManager.getSerializedChannelManager(),
           let networkGraph = fileManager.getSerializedNetworkGraph() {
            let channelMonitors = fileManager.getSerializedChannelMonitors()
            do {
                return try ChannelManagerConstructor(
                    channel_manager_serialized: channelManager,
                    channel_monitors_serialized: channelMonitors,
                    keys_interface: keysInterface,
                    fee_estimator: feeEstimator,
                    chain_monitor: chainMonitor,
                    filter: filter,
                    net_graph_serialized: networkGraph,
                    tx_broadcaster: broadcaster!, // Force unwrap since we definitely set it in L61
                    logger: logger,
                    enableP2PGossip: true
                )
            } catch {
                throw NodeError.noChannelManager
            }
        } else {
            throw NodeError.channelMaterialNotFound
        }
    }
    
    private func initializeChannelMaterialAndNetworkGraph(currentTipHash: [UInt8], currentTipHeight: UInt32, keysInterface: KeysInterface, chainMonitor: ChainMonitor, broadcaster: BroadcasterInterface) async throws -> ChannelManagerConstructor {
        var network = LDKNetwork_Regtest
        switch connectionType {
        case .testnet:
            network = LDKNetwork_Testnet
        default:
            network = LDKNetwork_Regtest
        }
        
        let genesisHash = [UInt8](repeating: 0, count: 32)
        
        let graph = NetworkGraph(genesis_hash: genesisHash, logger: logger)
        return ChannelManagerConstructor(
            network: network,
            config: UserConfig(),
            current_blockchain_tip_hash: currentTipHash,
            current_blockchain_tip_height: currentTipHeight,
            keys_interface: keysInterface,
            fee_estimator: feeEstimator,
            chain_monitor: chainMonitor,
            net_graph: graph,
            tx_broadcaster: broadcaster,
            logger: logger,
            enableP2PGossip: true
        )
    }
}
