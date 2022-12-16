//
//  RegtestBlockchainManager.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import Combine

class BitcoinCoreChainManager {
    let rpcUrl: URL
    
    private var anchorBlock: BlockDetails?
    private var connectedBlocks = [BlockDetails]()
    
    private let monitoringTracker = MonitoringTracker()
    private var chainListeners = [ChainListener]()
    
    var blockchainMonitorPublisher: AnyPublisher<Void, Error> {
        Timer.publish(every: 5.0, on: RunLoop.main, in: .default)
            .autoconnect()
            .flatMap { [unowned self] _ in
                Future { promise in
                    Task {
                        try await self.reconcileChaintips()
                        promise(.success(()))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    init(rpcProtocol: RpcProtocol, host: String, port: UInt, username: String, password: String) throws {
        guard let rpcUrl = URL(string: "\(rpcProtocol.rawValue)://\(username):\(password)@\(host):\(port)") else {
            throw ChainManagerError.invalidUrlString
        }
        
        self.rpcUrl = rpcUrl
    }
    
    func registerListener(_ listener: ChainListener) {
        self.chainListeners.append(listener)
    }
    
    /// This method takes in an `anchorHeight` and provides us with a way to make the requisite calls needed to Bitcoin Core in order to
    /// let `Listener`s know about blocks to connect.
    func preloadMonitor(anchorHeight: MonitorAnchor) async throws {
        // If tracker is already preloaded, don't try again.
        guard !(await self.monitoringTracker.preload()) else {
            return
        }
        
        var lastTrustedBlockHeight: UInt32
        let chaintipHeight = try await self.getChaintipHeight()
        switch anchorHeight {
        case .genesis:
            lastTrustedBlockHeight = 0
        case .block(let height):
            lastTrustedBlockHeight = height
        case .chaintip:
            lastTrustedBlockHeight = chaintipHeight
        }
        
        do {
            let anchorBlockHash = try await self.getBlockHashHex(height: lastTrustedBlockHeight)
            let anchorBlock = try await self.getBlock(hash: anchorBlockHash)
            connectedBlocks.append(anchorBlock)
        } catch {
            throw ChainManagerError.unknownAnchorBlock
        }
        
        if lastTrustedBlockHeight != chaintipHeight {
            do {
                try await self.connectBlocks(from: lastTrustedBlockHeight + 1, to: chaintipHeight)
            } catch ChainManagerError.unableToConnectBlock(let blockHeight) {
                print("Unable to connect to block at \(blockHeight). Stopping preload...")
            }
        }
    }
    
    func isMonitoring() async -> Bool {
        return await self.monitoringTracker.startTracking()
    }
    
    func getBogusAddress() async -> String {
        let scriptDetails = try! await decodeScript(script: [0, 1, 0])
        let fakeAddress = ((scriptDetails["segwit"] as! [String: Any])["addresses"] as! [String]).first!
        return fakeAddress
    }
}

// MARK: Helper Functions
extension BitcoinCoreChainManager {
    // Trigger a check of what's the latest
    private func reconcileChaintips() async throws {
        let currentChaintipHeight = try await self.getChaintipHeight()
        let currentChaintipHash = try await self.getChaintipHashHex()

        // Check if we area already at chain tip.
        guard let knownChaintip = self.connectedBlocks.last,
           knownChaintip.height != currentChaintipHeight && knownChaintip.hash != currentChaintipHash else {
            return
        }

        // create an array of the new blocks
        var addedBlocks = [BlockDetails]()
        if knownChaintip.height < currentChaintipHeight {
           // without this precondition, the range won't even work to begin with
           for addedBlockHeight in (knownChaintip.height + 1)...currentChaintipHeight {
               let addedBlockHash = try await self.getBlockHashHex(height: addedBlockHeight)
               let addedBlock = try await self.getBlock(hash: addedBlockHash)
               addedBlocks.append(addedBlock)
           }
        }

        while addedBlocks.isEmpty || addedBlocks.first!.previousblockhash != self.connectedBlocks.last!.hash {
           // we must keep popping until it matches
           let trimmingCandidate = self.connectedBlocks.last!
           if trimmingCandidate.height > currentChaintipHeight {
               // we can disconnect this block without prejudice
               _ = try await self.disconnectBlock()
               continue
           }
           let reorgedBlockHash = try await self.getBlockHashHex(height: trimmingCandidate.height)
           if reorgedBlockHash == trimmingCandidate.hash {
               // this block matches the one we already have
               break
           }
           let reorgedBlock = try await self.getBlock(hash: reorgedBlockHash)
           _ = try await self.disconnectBlock()
           addedBlocks.insert(reorgedBlock, at: 0)
        }

        for addedBlock in addedBlocks {
           try await self.connectBlock(block: addedBlock)
        }
    }
    
    private func callRpcMethod(method: String, params: Any) async throws -> [String: Any] {
        let body: [String: Any] = [
            "method": method,
            "params": params
        ]
        let jsonBody = try! JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: rpcUrl)
        request.httpMethod = "POST"
        request.httpBody = jsonBody
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed)
        // print("JSON-RPC response: \(response)")
        let responseDictionary = response as! [String: Any]
        if let responseError = responseDictionary["error"] as? [String: Any] {
            let errorDetails = RPCErrorDetails(message: responseError["message"] as! String, code: responseError["code"] as! Int64)
            print("error details: \(errorDetails)")
            throw RpcError.errorResponse(errorDetails)
        }
        return responseDictionary
    }
    
    private func connectBlocks(from: UInt32, to: UInt32) async throws {
        for currentBlockHeight in from...to {
            do {
                let currentBlockHash = try await self.getBlockHashHex(height: currentBlockHeight)
                let currentBlock = try await self.getBlock(hash: currentBlockHash)
                try await self.connectBlock(block: currentBlock)
            } catch {
                throw ChainManagerError.unableToConnectBlock(blockHeight: currentBlockHeight)
            }
        }
    }
    
    private func connectBlock(block: BlockDetails) async throws {
        if self.connectedBlocks.count > 0 {
            let lastConnectionHeight = self.connectedBlocks.last!.height
            if lastConnectionHeight + 1 != block.height {
                // trying to connect block out of order
                throw ChainObservationError.nonSequentialBlockConnection
            }
            let lastBlockHash = self.connectedBlocks.last!.hash
            if block.previousblockhash != lastBlockHash {
                // this should in principle never occur, as the caller should check and reconcile beforehand
                throw ChainObservationError.unhandledReorganization
            }
        }

        print("connecting block at \(block.height) with hex: \(block.hash)")

        if self.chainListeners.count > 0 {
            let binary = try await self.getBlockBinary(hash: block.hash)
            for listener in self.chainListeners {
                listener.blockConnected(block: binary, height: UInt32(block.height))
            }
        }

        self.connectedBlocks.append(block)
    }
    
    private func disconnectBlock() async throws -> BlockDetails {
        if self.connectedBlocks.count <= 1 {
            // we're about to disconnect the anchor block, which we can't
            throw ChainObservationError.excessiveReorganization
        }

        let poppedBlock = self.connectedBlocks.popLast()!

        print("disconnecting block \(poppedBlock.height) with hex: \(poppedBlock.hash)")

        if self.chainListeners.count > 0 {
            let blockHeader = try await self.getBlockHeader(hash: poppedBlock.hash)
            for listener in self.chainListeners {
                listener.blockDisconnected(header: blockHeader, height: UInt32(poppedBlock.height))
            }
        }

        return poppedBlock
    }
}

// MARK: Common ChainManager Functions
extension BitcoinCoreChainManager: RpcChainManager {
    func submitTransaction(transaction: [UInt8]) async throws -> String {
        let txHex = bytesToHexString(bytes: transaction)
        let response = try await self.callRpcMethod(method: "sendrawtransaction", params: [txHex])
        // returns the txid
        let result = response["result"] as! String
        return result
    }
}

// MARK: RPC Calls
extension BitcoinCoreChainManager {
    func getChaintipHeight() async throws -> UInt32 {
        let response = try await self.callRpcMethod(method: "getblockcount", params: [])
        let result = response["result"] as! UInt32
        return result
    }
    
    func getChaintipHash() async throws -> [UInt8] {
        let blockHashHex = try await self.getChaintipHashHex()
        return hexStringToBytes(hexString: blockHashHex)!
    }
    
    func getBlockHashHex(height: UInt32) async throws -> String {
        let response = try await self.callRpcMethod(method: "getblockhash", params: ["height": height])
        let result = response["result"] as! String
        return result
    }
    
    func getBlock(hash: String) async throws -> BlockDetails {
        let response = try await self.callRpcMethod(method: "getblock", params: [hash])
        let result = response["result"] as! [String: Any]
        let blockDetails = try JSONDecoder().decode(BlockDetails.self, from: JSONSerialization.data(withJSONObject: result))
        return blockDetails
    }
    
    func getBlockBinary(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: "getblock", params: [hash, 0])
        let result = response["result"] as! String
        let blockData = hexStringToBytes(hexString: result)!
        return blockData
    }
    
    func getChaintipHashHex() async throws -> String {
        let chainInfo = try await self.getChainInfo()
        return chainInfo["bestblockhash"] as! String
    }
    
    func getChainInfo() async throws -> [String: Any] {
        let response = try await self.callRpcMethod(method: "getblockchaininfo", params: [])
        let result = response["result"] as! [String: Any]
        return result
    }
    
    func getBlockHeader(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: "getblockheader", params: [hash, false])
        let result = response["result"] as! String
        let blockHeader = hexStringToBytes(hexString: result)!
        assert(blockHeader.count == 80)
        return blockHeader
    }
    
    public func getTransaction(with hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: "getrawtransaction", params: [hash])
        let txHex = response["result"] as! String
        let transaction = hexStringToBytes(hexString: txHex)!
        return transaction
    }
    
    /**
     Decode an arbitary script. Can be an output script, a redeem script, or anything else
     - Parameter script: byte array serialization of script
     - Returns: Object with various possible interpretations of the script
     - Throws:
     */
    public func decodeScript(script: [UInt8]) async throws -> [String: Any] {
        let scriptHex = bytesToHexString(bytes: script)
        let response = try await self.callRpcMethod(method: "decodescript", params: [scriptHex])
        let result = response["result"] as! [String: Any]
        return result
    }

    /**
     Mine regtest blocks
     - Parameters:
       - number: The number of blocks to mine
       - coinbaseDestinationAddress: The output address to be used in the coinbase transaction(s)
     - Returns: Array of the mined blocks' hashes
     - Throws: If the RPC connection fails or the call results in an error
     */
    func mineBlocks(number: Int, coinbaseDestinationAddress: String) async throws -> [String]  {
        let response = try await self.callRpcMethod(method: "generatetoaddress", params: [
            "nblocks": number,
            "address": coinbaseDestinationAddress
        ])
        let result = response["result"] as! [String]
        return result
    }
}

// MARK: Supporting Data Structures
extension BitcoinCoreChainManager {
    struct BlockDetails: Codable {
        let hash: String
        let version: Int64
        let mediantime: Int64
        let nonce: Int64
        let chainwork: String
        let nTx: Int64
        let time: Int64
        let weight: Int64
        let merkleroot: String
        let size: Int64
        let confirmations: Int64
        let versionHex: String
        let height: UInt32
        let difficulty: Double
        let strippedsize: Int64
        let previousblockhash: String?
        let bits: String
        let tx: [String]
    }
    
    enum RpcProtocol: String {
        case http = "http"
        case https = "https"
    }
    
    enum ChainManagerError: Error {
        case invalidUrlString
        case unknownAnchorBlock
        case unableToConnectBlock(blockHeight: UInt32)
    }
}

fileprivate func hexStringToBytes(hexString: String) -> [UInt8]? {
    let hexStr = hexString.dropFirst(hexString.hasPrefix("0x") ? 2 : 0)

    guard hexStr.count % 2 == 0 else {
        return nil
    }

    var newData = [UInt8]()

    var indexIsEven = true
    for i in hexStr.indices {
        if indexIsEven {
            let byteRange = i...hexStr.index(after: i)
            guard let byte = UInt8(hexStr[byteRange], radix: 16) else {
                return nil
            }
            newData.append(byte)
        }
        indexIsEven.toggle()
    }
    return newData
}

fileprivate func bytesToHexString(bytes: [UInt8]) -> String {
    let format = "%02hhx" // "%02hhX" (uppercase)
    return bytes.map {
        String(format: format, $0)
    }
    .joined()
}
