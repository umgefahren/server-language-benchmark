//
//  SocketHandler.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 07.04.22.
//

import Foundation
import SystemPackage


actor SocketHandler {
    private static let bufferSize = 1024
    
    private var fileDescriptor: FileDescriptor
    private var buffer: UnsafeMutableBufferPointer<CChar>
    private var bufferStart, bufferEnd, searchStart: Int
    private var atEOF: Bool
    
    
    private var readBuffer: UnsafeMutableRawBufferPointer {
        .init(start: self.buffer.baseAddress?.advanced(by: self.bufferEnd), count: self.buffer.count - self.bufferEnd)
    }
    
    
    init(withFileDescriptor fileDescriptor: Int32) {
        self.fileDescriptor = .init(rawValue: fileDescriptor)
        self.buffer = .allocate(capacity: Self.bufferSize)
        self.bufferStart = 0
        self.bufferEnd = 0
        self.searchStart = 0
        self.atEOF = false
    }
    
    deinit {
        self.buffer.deallocate()
    }
    
    
    func nextLine() -> Substring? {
        self.searchStart = self.bufferStart
        
        while !self.atEOF {
            if let i = self.buffer[self.searchStart..<self.bufferEnd].firstIndex(of: 0x0A) {
                let stringStart = self.bufferStart
                
                self.bufferStart = i + 1
                
                guard let string = String(bytesNoCopy: self.buffer.baseAddress! + stringStart, length: i - stringStart, encoding: .ascii, freeWhenDone: false) else { return nil }
                
                return .init(string)
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

            do {
                let bytesRead = try self.fileDescriptor.read(into: self.readBuffer)
                
                if bytesRead == 0 {
                    self.atEOF = true
                    
                    guard let string = String(bytesNoCopy: self.buffer.baseAddress! + self.bufferStart, length: self.bufferEnd - self.bufferStart, encoding: .ascii, freeWhenDone: false) else { return nil }
                    
                    return .init(string)
                } else {
                    self.bufferEnd += bytesRead
                }
            } catch let error as Errno {
                if error == .resourceTemporarilyUnavailable || error == .wouldBlock {
                    continue
                }
                
                self.atEOF = true
            } catch {
                fatalError("Unreachable")
            }
        }
        
        return nil
    }
    
    
    func readBytes(maximumCount: Int) -> UnsafeRawBufferPointer? {
        while !self.atEOF {
            if self.bufferEnd - self.bufferStart > 0 {
                let start = self.bufferStart
                
                self.bufferStart = min(self.bufferEnd, self.bufferStart + maximumCount)
                
                guard let rawBase = UnsafeRawPointer(self.buffer.baseAddress) else { return nil }
                
                return .init(start: rawBase.advanced(by: start), count: self.bufferStart - start)
            }

            self.bufferStart = 0
            self.bufferEnd = 0
            
            do {
                let bytesRead = try self.fileDescriptor.read(into: self.readBuffer)
                
                if bytesRead == 0 {
                    self.atEOF = true
                    
                    guard let rawBase = UnsafeRawPointer(self.buffer.baseAddress) else { return nil }
                    
                    return .init(start: rawBase.advanced(by: self.bufferStart), count: self.bufferEnd - self.bufferStart)
                } else {
                    self.bufferEnd += bytesRead
                }
            } catch let error as Errno {
                if error == .resourceTemporarilyUnavailable || error == .wouldBlock {
                    continue
                }
                
                self.atEOF = true
            } catch {
                fatalError("Unreachable")
            }
        }
        
        return nil
    }
    
    
    func write<S>(_ string: S, appendingNewline: Bool = true) where S: StringProtocol {
        do {
            try self.fileDescriptor.writeAll(string.utf8)
            
            if appendingNewline {
                try self.fileDescriptor.writeAll("\n".utf8)
            }
        } catch let error as Errno {
            _ = error
        } catch {
            fatalError("Unreachable")
        }
    }
    
    
    func writeContents(ofFile filePath: FilePath, size: Int) {
        let fileBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: min(size, 1024), alignment: MemoryLayout<UInt8>.alignment)
        defer {
            fileBuffer.deallocate()
        }
        
        do {
            let fileDescriptor = try FileDescriptor.open(filePath, .readOnly)
            
            var remainingBytes = size
            while remainingBytes > 0 {
                let readBytes = try fileDescriptor.read(into: fileBuffer)
                
                try self.fileDescriptor.writeAll(fileBuffer[..<min(readBytes, remainingBytes)])
                
                remainingBytes -= readBytes
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
