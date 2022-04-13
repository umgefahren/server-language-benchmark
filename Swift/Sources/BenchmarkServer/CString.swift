//
//  CString.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 13.04.22.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

import Dispatch


public struct CString {
    @usableFromInline
    internal static let _digitsZeroThroughFive: ClosedRange<CChar> = "0"..."5"
    
    
    @usableFromInline
    internal class _Storage {
        @usableFromInline
        internal let _slice: Slice<UnsafeBufferPointer<CChar>>
        @usableFromInline
        internal let _shouldDeallocate: Bool
        
        @inlinable
        init(_slice slice: Slice<UnsafeBufferPointer<CChar>>, shouldDeallocate: Bool) {
            self._slice = slice
            self._shouldDeallocate = shouldDeallocate
        }
        
        
        deinit {
            if self._shouldDeallocate {
                self._slice.base.deallocate()
            }
        }
    }
    
    
    @usableFromInline
    internal let _storage: _Storage
    
    
    @inlinable
    public init(staticString string: UnsafePointer<CChar>) {
        let count = strlen(string)
        
        self._storage = .init(_slice: UnsafeBufferPointer(start: string, count: count)[...], shouldDeallocate: false)
    }
    
    
    @inlinable
    public init(slice: Slice<UnsafeBufferPointer<CChar>>) {
        self._storage = .init(_slice: slice, shouldDeallocate: false)
    }
    
    
    @inlinable
    internal init(_slice slice: Slice<UnsafeBufferPointer<CChar>>, shouldDeallocate: Bool) {
        self._storage = .init(_slice: slice, shouldDeallocate: shouldDeallocate)
    }
    
    
    @inlinable
    var rawPointer: UnsafeRawPointer? {
        guard let base = self._storage._slice.base.baseAddress else { return nil }
        
        return .init(base.advanced(by: self._storage._slice.startIndex))
    }
    
    @inlinable
    var rawBufferPointer: UnsafeRawBufferPointer? {
        .init(start: self.rawPointer, count: self._storage._slice.count)
    }
    
    
    @inlinable
    var copy: CString {
        let newBuffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity: self._storage._slice.count)
        
        memcpy(.init(newBuffer.baseAddress), self.rawPointer, self._storage._slice.count)
        
        return .init(_slice: .init(base: .init(newBuffer), bounds: 0..<self._storage._slice.count), shouldDeallocate: true)
    }
    
    
    @inlinable
    var isValidKeyOrValue: Bool {
        self._storage._slice.count > 0 && self._storage._slice.allSatisfy { $0.isLetter || $0.isDigit }
    }
    
    
    @inlinable
    var trimmed: CString {
        if self._storage._slice.isEmpty { return self }
        
        var leftIndex = self._storage._slice.startIndex
        
        while self._storage._slice[leftIndex].isSpace {
            leftIndex += 1
            
            
            if leftIndex == self._storage._slice.endIndex {
                return .init(slice: self._storage._slice[leftIndex..<leftIndex])
            }
        }
        
        var rightIndex = self._storage._slice.endIndex - 1
        
        while rightIndex > leftIndex && self._storage._slice[rightIndex].isSpace {
            rightIndex -= 1
        }
        
        return .init(slice: self._storage._slice[leftIndex..<(rightIndex + 1)])
    }
    
    
    @inlinable
    func parseAsInterval() -> DispatchTimeInterval? {
        var iterator = self._storage._slice.makeIterator()
        
        guard let hoursUpper = iterator.next(), hoursUpper.isDigit else { return nil }
        guard let hoursLower = iterator.next(), hoursLower.isDigit else { return nil }
        guard iterator.next() == "h" && iterator.next() == "-" else { return nil }
        
        guard let minutesUpper = iterator.next(), Self._digitsZeroThroughFive.contains(minutesUpper) else { return nil }
        guard let minutesLower = iterator.next(), minutesLower.isDigit else { return nil }
        guard iterator.next() == "m" && iterator.next() == "-" else { return nil }
        
        guard let secondsUpper = iterator.next(), Self._digitsZeroThroughFive.contains(secondsUpper) else { return nil }
        guard let secondsLower = iterator.next(), secondsLower.isDigit else { return nil }
        guard iterator.next() == "s" && iterator.next() == nil else { return nil }
        
        
        let hours = Int((hoursUpper - "0") * 10 + (hoursLower - "0"))
        let minutes = Int((minutesUpper - "0") * 10 + (minutesLower - "0"))
        let seconds = Int((secondsUpper - "0") * 10 + (secondsLower - "0"))
        
        return .seconds(hours * 3600 + minutes * 60 + seconds)
    }
}


extension CString: Collection {
    @inlinable
    public var startIndex: Int {
        self._storage._slice.startIndex
    }
    
    @inlinable
    public var endIndex: Int {
        self._storage._slice.endIndex
    }
    
    
    @inlinable
    public subscript(position: Int) -> CChar {
        self._storage._slice[position]
    }
    
    
    @inlinable
    public subscript(bounds: Range<Int>) -> CString {
        .init(slice: self._storage._slice[bounds])
    }
    
    
    @inlinable
    public var indices: Range<Int> {
        self._storage._slice.indices
    }
    
    @inlinable
    public var isEmpty: Bool {
        self._storage._slice.isEmpty
    }
    
    @inlinable
    public var count: Int {
        self._storage._slice.count
    }
    
    
    @inlinable
    public func index(_ i: Int, offsetBy distance: Int) -> Int {
        self._storage._slice.index(i, offsetBy: distance)
    }
    
    
    @inlinable
    public func index(_ i: Int, offsetBy distance: Int, limitedBy limit: Int) -> Int? {
        self._storage._slice.index(i, offsetBy: distance, limitedBy: limit)
    }
    
    
    @inlinable
    public func distance(from start: Int, to end: Int) -> Int {
        self._storage._slice.distance(from: start, to: end)
    }
    
    
    @inlinable
    public func index(after i: Int) -> Int {
        self._storage._slice.index(after: i)
    }
    
    @inlinable
    public func formIndex(after i: inout Int) {
        self._storage._slice.formIndex(after: &i)
    }
}

extension CString: RandomAccessCollection {
    @inlinable
    public func index(before i: Int) -> Int {
        self._storage._slice.index(before: i)
    }
}

extension CString: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral string: StaticString) {
        self.init(staticString: UnsafeRawPointer(string.utf8Start).assumingMemoryBound(to: CChar.self))
    }
}

extension CString: ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral string: StaticString) {
        self.init(staticString: UnsafeRawPointer(string.utf8Start).assumingMemoryBound(to: CChar.self))
    }
}
 
extension CString: ExpressibleByStringLiteral {
    public init(stringLiteral string: StaticString) {
        self.init(staticString: UnsafeRawPointer(string.utf8Start).assumingMemoryBound(to: CChar.self))
    }
}

extension CString: Equatable {
    public static func ==(lhs: CString, rhs: CString) -> Bool {
        lhs._storage._slice.count == rhs._storage._slice.count && memcmp(lhs.rawPointer, rhs.rawPointer, lhs._storage._slice.count) == 0
    }
}

extension CString: Hashable {
    public func hash(into hasher: inout Hasher) {
        if let rawBufferPointer = self.rawBufferPointer {
            hasher.combine(bytes: rawBufferPointer)
        }
        
        hasher.combine(0xFF as UInt8)
    }
}

extension CString: @unchecked Sendable {}
