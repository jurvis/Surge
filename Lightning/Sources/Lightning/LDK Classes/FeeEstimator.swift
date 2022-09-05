//
//  FeeEstimator.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import LightningDevKit

class FeeEstimator: LightningDevKit.FeeEstimator {
    override func get_est_sat_per_1000_weight(confirmation_target: LDKConfirmationTarget) -> UInt32 {
        // This number is the feerate to work with LND nodes in testnet
        // (https://github.com/lightningnetwork/lnd/blob/master/chainreg/chainregistry.go#L140-L142)
        return 1250
    }
}
