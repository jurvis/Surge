//
//  RpcChainManager.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation

protocol RpcChainManager {
    func submitTransaction(transaction: [UInt8]) async throws -> String
}
