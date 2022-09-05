//
//  RpcUtils.swift
//  A set of data structures we use for expressing errors with our RPC interfaces
//
//  Created by Jurvis on 9/5/22.
//

import Foundation

enum RpcError: Error {
    case tcpError
    case invalidJson
    case errorResponse(RPCErrorDetails)
}

struct RPCErrorDetails {
    let message: String
    let code: Int64
}

public enum ChainObservationError: Error {
    case alreadyInProgress
    case nonSequentialBlockConnection
    case unhandledReorganization
    case excessiveReorganization
}
