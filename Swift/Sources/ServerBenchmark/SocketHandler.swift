//
//  SocketHandler.swift
//  ServerBenchmark
//
//  Created by Josef Zoller on 07.04.22.
//

import Foundation


class SocketHandler {
    private static let bufferSize = 1000
    private static let newlineData = "\n".data(using: .utf8)!
    
    private var fileHandle: FileHandle
    private var buffer: Data
    private var atEOF: Bool
    
    
    init(withFileDescriptor fileDescriptor: Int32) {
        self.fileHandle = .init(fileDescriptor: fileDescriptor)
        self.buffer = Data(capacity: Self.bufferSize)
        self.atEOF = false
    }
    
    
    func nextLine() throws -> String? {
        while !self.atEOF {
            if let range = self.buffer.range(of: Self.newlineData) {
                let line = String(data: self.buffer.subdata(in: 0..<range.lowerBound), encoding: .utf8)
                
                self.buffer.removeSubrange(0..<range.upperBound)
                
                return line
            } else {
                guard let tmpData = try fileHandle.read(upToCount: Self.bufferSize) else {
                    self.atEOF = true
                    return nil
                }
                
                if tmpData.count > 0 {
                    buffer.append(tmpData)
                } else {
                    self.atEOF = true
                    
                    if buffer.count > 0 {
                        let line = String(data: self.buffer, encoding: .utf8)
                        
                        self.buffer.count = 0
                        
                        return line
                    }
                }
            }
        }
        
        return nil
    }
    
    
    func write<S>(_ string: S, appendingNewline: Bool = true) throws where S: StringProtocol {
        guard let data = string.data(using: .utf8) else { return }
        
        try self.fileHandle.write(contentsOf: data)
        
        if appendingNewline {
            try self.fileHandle.write(contentsOf: Self.newlineData)
        }
    }
}
