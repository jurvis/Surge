//
//  RegtestConfig.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation

public struct RegtestConfig {
    let rpcUsername: String
    let rpcPassword: String
    let rpcPort: UInt
    let rpcDomain: String
    
    public init(rpcUsername: String, rpcPassword: String, rpcPort: UInt, rpcDomain: String) {
        self.rpcUsername = rpcUsername
        self.rpcPassword = rpcPassword
        self.rpcPort = rpcPort
        self.rpcDomain = rpcDomain
    }
}
