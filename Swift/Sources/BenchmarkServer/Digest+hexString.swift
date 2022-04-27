//
//  Digest+hexString.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 27.04.22.
//

import Crypto


private let charA = UInt8(UnicodeScalar("a").value)
private let char0 = UInt8(UnicodeScalar("0").value)

private func itoh(_ value: UInt8) -> UInt8 {
    return (value > 9) ? (charA + value - 10) : (char0 + value)
}

extension Digest {
    var hexString: String {
        let hexCount = Self.byteCount * 2
        let hexPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: hexCount)
        
        self.withUnsafeBytes { buffer in
            var offset = 0
            for byte in buffer {
                hexPointer[offset * 2] = itoh((byte >> 4) & 0xF)
                hexPointer[offset * 2 + 1] = itoh(byte & 0xF)
                offset += 1
            }
        }
        
        return String(bytesNoCopy: hexPointer, length: hexCount, encoding: .ascii, freeWhenDone: true)!
    }
}
