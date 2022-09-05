//
//  RegtestConfig.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation

public struct BitcoinCoreRpcConfig {
    let username: String
    let password: String
    let port: UInt
    let host: String
    
    public init(username: String, password: String, port: UInt, host: String) {
        self.username = username
        self.password = password
        self.port = port
        self.host = host
    }
}
