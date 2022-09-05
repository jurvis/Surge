//
//  MonitorAnchor.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation

/**
 Which block height should the monitor start from?
 */
public enum MonitorAnchor {
    /**
     Start from the genesis block, and catch up on all data thence
     */
    case genesis
    /**
     Start from a specific block height, and catch up through the chaintip
     */
    case block(UInt32)
    /**
     Start from the chaintip, and only register new blocks as they come
     */
    case chaintip
}
