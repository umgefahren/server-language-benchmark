//
//  CStringSlice.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 07.04.22.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif


public typealias CStringSlice = UnsafeBufferPointer<CChar>.SubSequence


extension CStringSlice {
    private static let lower: ClosedRange<CChar> = "a"..."z"
    private static let upper: ClosedRange<CChar> = "A"..."Z"
    private static let digit: ClosedRange<CChar> = "0"..."9"
    
    
    init(nullTerminated string: UnsafePointer<CChar>) {
        let count = strlen(string)
        
        self = UnsafeBufferPointer(start: string, count: count)[...]
    }
    
    
    var isValidKeyOrValue: Bool {
        self.count > 0 && self.allSatisfy { Self.lower.contains($0) || Self.upper.contains($0) || Self.digit.contains($0) }
    }
    
    
    var rawPointer: UnsafeRawPointer? {
        guard let base = self.base.baseAddress else { return nil }
        
        return .init(base.advanced(by: self.startIndex))
    }
    
    var rawBufferPointer: UnsafeRawBufferPointer? {
        .init(start: self.rawPointer, count: self.count)
    }
    
    
    var trimmed: CStringSlice {
        if self.isEmpty { return self }
        
        var leftIndex = self.startIndex
        
        while self[leftIndex].isSpace {
            leftIndex += 1
            
            
            if leftIndex == self.endIndex {
                return self[leftIndex..<leftIndex]
            }
        }
        
        var rightIndex = self.endIndex - 1
        
        while rightIndex > leftIndex && self[rightIndex].isSpace {
            rightIndex -= 1
        }
        
        return self[leftIndex..<(rightIndex + 1)]
    }
    
    
    var copy: CStringSlice {
        let newBuffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity: self.count)
        
        memcpy(.init(newBuffer.baseAddress), self.rawPointer, self.count)
        
        return .init(base: .init(newBuffer), bounds: 0..<self.count)
    }
    
    
    func deallocate() {
        self.base.deallocate()
    }
}

extension CStringSlice: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral string: StaticString) {
        self.init(nullTerminated: UnsafeRawPointer(string.utf8Start).assumingMemoryBound(to: CChar.self))
    }
}

extension CStringSlice: ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral string: StaticString) {
        self.init(nullTerminated: UnsafeRawPointer(string.utf8Start).assumingMemoryBound(to: CChar.self))
    }
}
 
extension CStringSlice: ExpressibleByStringLiteral {
    public init(stringLiteral string: StaticString) {
        self.init(nullTerminated: UnsafeRawPointer(string.utf8Start).assumingMemoryBound(to: CChar.self))
    }
}

extension CStringSlice: Equatable {
    public static func ==(lhs: CStringSlice, rhs: CStringSlice) -> Bool {
        lhs.count == rhs.count && memcmp(lhs.rawPointer, rhs.rawPointer, lhs.count) == 0
    }
}

extension CStringSlice: Hashable {
    public func hash(into hasher: inout Hasher) {
        if let rawBufferPointer = self.rawBufferPointer {
            hasher.combine(bytes: rawBufferPointer)
        }
        
        hasher.combine(0xFF as UInt8)
    }
}
