//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

class Logger: LightningDevKit.Logger {
    override func log(record: Bindings.Record) {
        print("DEBUG:: (\(record.get_level())): \(record.get_file()):\(record.get_line()):\n> \(record.get_args())\n")
    }
}
