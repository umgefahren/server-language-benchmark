//
//  Sequence+asyncMap.swift
//  NIOBenchmarkServer
//
//  Created by Josef Zoller on 09.04.22.
//

extension Sequence {
    func asyncMap<T>(_ transform: @Sendable (Element) async throws -> T) async rethrows -> [T] {
        let initialCapacity = self.underestimatedCount
        var result = ContiguousArray<T>()
        result.reserveCapacity(initialCapacity)

        var iterator = self.makeIterator()

        for _ in 0..<initialCapacity {
            try await result.append(transform(iterator.next()!))
        }
        
        while let element = iterator.next() {
            try await result.append(transform(element))
        }
        
        return Array(result)
    }
}
