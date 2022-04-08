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
    
    private var fileDescriptor: Int32
    private var buffer: UnsafeMutableBufferPointer<CChar>
    private var bufferStart, bufferEnd, searchStart: Int
    private var atEOF: Bool
    
    
    init(withFileDescriptor fileDescriptor: Int32) {
        self.fileDescriptor = fileDescriptor
        self.buffer = .allocate(capacity: Self.bufferSize)
        self.buffer.assign(repeating: 0)
        self.bufferStart = 0
        self.bufferEnd = 0
        self.searchStart = 0
        self.atEOF = false
    }
    
    
    func nextLine() throws -> String? {
        self.searchStart = self.bufferStart
        
        while !self.atEOF {
            if let i = self.buffer[self.searchStart..<self.bufferEnd].firstIndex(of: 0x0A) {
                let stringStart = self.bufferStart
                
                self.bufferStart = i + 1
                
                return .init(bytesNoCopy: self.buffer.baseAddress! + stringStart, length: i - stringStart, encoding: .utf8, freeWhenDone: false)
            }

            if self.buffer.count < self.bufferEnd - self.bufferStart + Self.bufferSize {
                let oldBuffer = self.buffer
                self.buffer = .allocate(capacity: self.bufferEnd - self.bufferStart + Self.bufferSize)
                self.buffer.assign(repeating: 0)

                self.buffer.baseAddress?.assign(from: oldBuffer.baseAddress! + self.bufferStart, count: self.bufferEnd - self.bufferStart)

                self.bufferEnd = self.bufferEnd - self.bufferStart
                self.bufferStart = 0

                oldBuffer.deallocate()
            } else if self.bufferStart != 0 {
                self.buffer.baseAddress?.moveAssign(from: self.buffer.baseAddress! + self.bufferStart, count: self.bufferEnd - self.bufferStart)

                self.bufferEnd = self.bufferEnd - self.bufferStart
                self.bufferStart = 0
            }

            self.searchStart = self.bufferEnd

            let bytesRead = read(self.fileDescriptor, self.buffer.baseAddress! + self.bufferEnd, Self.bufferSize)
            if bytesRead < 0 {
                self.atEOF = true
            } else if bytesRead == 0 {
                self.atEOF = true

                return .init(bytesNoCopy: self.buffer.baseAddress! + self.bufferStart, length: self.bufferEnd - self.bufferStart, encoding: .utf8, freeWhenDone: false)
            } else {
                self.bufferEnd += bytesRead
            }

        }
        
        return nil
    }
    
    
    func write<S>(_ string: S, appendingNewline: Bool = true) throws where S: StringProtocol {
        let count = string.count
        
        string.withCString {
            _ = Darwin.write(self.fileDescriptor, $0, count)
        }
        
        if appendingNewline {
            Darwin.write(self.fileDescriptor, "\n", 1)
        }
    }
}
