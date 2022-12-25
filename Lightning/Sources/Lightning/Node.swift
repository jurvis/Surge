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
    
    /// Start the Lightning node
    public func start() async throws {
        // (1) Retrieve our key's 32-byte seed
        guard let keySeed = fileManager.getKeysSeed() else { throw NodeError.keySeedNotFound }
        
        let timestampInSeconds = UInt64(Date().timeIntervalSince1970)
        let timestampInNanoseconds = UInt32(truncating: NSNumber(value: timestampInSeconds * 1000 * 1000))
        
        // (2) Setup KeysManager with `keySeed`. With add entropy using the current time. See this comment for more information: https://docs.rs/lightning/0.0.112/lightning/chain/keysinterface/struct.KeysManager.html#method.new
        keysManager = KeysManager(seed: keySeed, starting_time_secs: timestampInSeconds, starting_time_nanos: timestampInNanoseconds)
        
        // (3) Grabs an instance of KeysInterface, we will need it later to construct a ChannelManager
        guard let keysInterface = keysManager?.as_KeysInterface() else {
            throw NodeError.keyInterfaceFailure
        }
        
        // (4) Initialize rpcInterface, which represents a series of chain methods that are necessary for chain sync.
        // Note: this is an API design unique to Surge. We introduce the `RpcChainManager` protocol to allow us to
        // interact with different types of block sources with just a different choice of a `RpcChainManager` instance.
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
        
        // (5) Initialized Broadcaster, primarily responsible for broadcasting requisite transaction on-chain.
        broadcaster = Broadcaster(rpcInterface: rpcInterface)
        
        // (6) Initialize a ChainMonitor. As the name describes, this is what we will use to watch on-chain activity
        // related to our channels. You can think of Chain Sync as the nervous system of the Lightning node. Its mostly responsible
        // for detecting stimuli that is relevant for its purposes, and feeds information back to the brain (`ChannelManager`)
        let chainMonitor = ChainMonitor(
            chain_source: Option_FilterZ(value: filter),
            broadcaster: broadcaster!, // Force unwrap since we definitely set it in L61
            logger: logger,
            feeest: feeEstimator,
            persister: ChannelPersister()
        )
        
        // (7) Do requisite chain sync to start.
        if case .regtest = connectionType,
           let rpcInterface = rpcInterface as? BitcoinCoreChainManager {
            // If we're using Bitcoin Core, we will tell the ChainMonitor to connect blocks up to the latest chain tip.
            try await rpcInterface.preloadMonitor(anchorHeight: .chaintip)
        }
        
        // (8) Construct ChannelManager. The ChannelManager, as mentioned earlier, is like the brain of the node. It is responsible for
        // sending messages to appropriate channels, track HTLCs, forward onion packets, and also track a user's channels. It can also be
        // persisted on disk, which is what you generally want to do as often as possible -- this is equivalent to a "node backup".
        // The general advice here is to make sure that your `ChannelManager` *is encrypted*, because you can certainly glean information
        // about a user's payment history if they get leaked out in the clear.
        if fileManager.hasChannelMaterialAndNetworkGraph {
            // Load our channel manager from disk
            channelManagerConstructor = try await loadChannelManagerConstructor(keysInterface: keysInterface, chainMonitor: chainMonitor)
        } else {
            // An existing ChannelManager does not exist on disk, create new channel material and network graph
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
        
        // Create shared instance reference to these objects, so we can use them for opening and managing channels and connecting to peers,
        // respectively.
        channelManager = channelManagerConstructor!.channelManager // we just set ChannelManagerConstructor above
        peerManager = channelManagerConstructor!.peerManager
        tcpPeerHandler = channelManagerConstructor!.getTCPPeerHandler()
        
        // (9) Initialize Persister, which is primarily responsible for persisting `ChannelManager`, `Scorer`, and `NetworkGraph` to disk.
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
    
    /// Connect to a Peer on the Network.
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
    
    public func requestChannelOpen(_ pubKeyHex: String, channelValue: UInt64, reserveAmount: UInt64) async throws -> ChannelOpenInfo {
        guard let channelManager = channelManager else {
            throw NodeError.Channels.channelManagerNotFound
        }
        
        // open_channel
        let theirNodeId = pubKeyHex.toByteArray()
        let config = UserConfig()
        let channelOpenResult = channelManager.create_channel(
            their_network_key: theirNodeId,
            channel_value_satoshis: channelValue,
            push_msat: reserveAmount,
            user_channel_id: 42,
            override_config: config
        )
        
        // See if peer has returned `accept_channel`
        if channelOpenResult.isOk() {
            let managerEvents = await getManagerEvents(expectedCount: 1)
            let managerEvent = managerEvents[0]
            // FIXME: Handle event where opening channel can fail (< min funding amount, wrong chain, etc.)
            // The event takes on the following schema: https://docs.rs/lightning/0.0.112/lightning/util/events/enum.Event.html#variant.FundingGenerationReady
            // In particular, `output_script` is the script we should be using in the transaction output. It basically
            // looks something like: 2 <Alice_funding_pubkey> <Bob_funding_pubkey> 2 CHECKMULTISIG
            let fundingReadyEvent = managerEvent.getValueAsFundingGenerationReady()!
            
            return ChannelOpenInfo(
                fundingOutputScript: fundingReadyEvent.getOutput_script(),
                temporaryChannelId: fundingReadyEvent.getTemporary_channel_id(),
                counterpartyNodeId: pubKeyHex.toByteArray()
            )
        } else if let errorDetails = channelOpenResult.getError() {
            throw errorDetails.getLDKError()
        }
        
        throw NodeError.Channels.unknown
    }
    
    public func getFundingTransactionScriptPubKey(outputScript: [UInt8]) async -> String? {
        guard let rpcInterface = rpcInterface,
              let decodedScript = try? await rpcInterface.decodeScript(script: outputScript),
              let addresses = decodedScript["addresses"] as? [String] else {
            return nil
        }
        
        return addresses.first
    }
    
    public func getFundingTransaction(fundingTxid: String) async -> [UInt8] {
        // FIXME: We can probably not force unwrap here if we can carefully intialize rpcInterface in the Node's initializer
        return try! await rpcInterface!.getTransaction(with: fundingTxid)
    }
    
    // You will need channelOpenInfo from `requestChannelOpen`, and `fundingTransaction` from `getFundingTransaction`
    public func openChannel(channelOpenInfo: ChannelOpenInfo, fundingTransaction: [UInt8]) async throws -> Bool {
        guard let channelManager = channelManager else {
            throw NodeError.Channels.channelManagerNotFound
        }
        
        // Create the funding transaction and do the `funding_created/funding_signed` dance with our counterparty.
        // After that, LDK will automatically broadcast it via the `BroadcasterInterface` we gave `ChannelManager`.
        var fundingResult: LightningDevKit.Result_NoneAPIErrorZ
        fundingResult = channelManager.funding_transaction_generated(
            temporary_channel_id: channelOpenInfo.temporaryChannelId,
            counterparty_node_id: channelOpenInfo.counterpartyNodeId,
            funding_transaction: fundingTransaction
        )
        
        if case .regtest(_) = connectionType {
            // Let's manually add 6 confirmations to confirm the channel open
            let coreChainManager = rpcInterface as! BitcoinCoreChainManager
            let fakeAddress = await coreChainManager.getBogusAddress()
            _ = try! await coreChainManager.mineBlocks(
                number: 6,
                coinbaseDestinationAddress: fakeAddress
            )
        }
        
        if fundingResult.isOk() {
            return true
        } else if let error = fundingResult.getError()?.getLDKError() {
            throw error
        }
        
        throw NodeError.Channels.fundingFailure
    }
}

extension Node {
    public struct ChannelOpenInfo {
        public let fundingOutputScript: [UInt8]
        public let temporaryChannelId: [UInt8]
        public let counterpartyNodeId: [UInt8]
    }
}

// MARK: Publishers
extension Node {
    public var connectedPeers: AnyPublisher<[String], Never> {
        Timer.publish(every: 5, on: .main, in: .default)
            .autoconnect()
            .prepend(Date())
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
    /// Receives downstream events from an upstream `Publisher` of `RpcChainManager`. Primarily used for reconciling chain tip.
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
    
    /// Used for loading a channel manager from the Documents directory.
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
    
    private func getManagerEvents(expectedCount: UInt) async -> [Event] {
       if let _ = channelManagerConstructor {
           while true {
               if await self.pendingEventTracker.getCount() >= expectedCount {
                   return await self.pendingEventTracker.getAndClearEvents()
               }
               await self.pendingEventTracker.awaitAddition()
           }
       }
       return []
   }
}
