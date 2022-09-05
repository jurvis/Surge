//
//  File.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation

extension String {
    func toByteArray() -> [UInt8] {
        let length = self.count
        if length & 1 != 0 {
            return []
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = self.startIndex
        for _ in 0..<length/2 {
            let nextIndex = self.index(index, offsetBy: 2)
            if let b = UInt8(self[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return []
            }
            index = nextIndex
        }
        return bytes
    }
}

extension Collection where Iterator.Element == UInt8 {
    func toHexString() -> String {
        let format = "%02hhx" // "%02hhX" (uppercase)
        return self.map {
            String(format: format, $0)
        }
        .joined()
    }
}
