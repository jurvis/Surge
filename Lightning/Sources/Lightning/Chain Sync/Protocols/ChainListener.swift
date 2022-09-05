//
//  File.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation

public protocol ChainListener {
    func blockConnected(block: [UInt8], height: UInt32);
    func blockDisconnected(header: [UInt8]?, height: UInt32);
}
