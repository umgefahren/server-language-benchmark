//
//  Substring+Helpers.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 13.04.22.
//

import Dispatch


extension Substring {
    @usableFromInline
    internal static let _digitsZeroThroughFive: ClosedRange<Character> = "0"..."5"
    
    @usableFromInline
    internal static let _zeroASCIIValue = Character("0").asciiValue.unsafelyUnwrapped
    
    
    @inlinable
    var copy: Substring {
        self.withCString {
            .init(cString: $0)
        }
    }
    
    
    @inlinable
    var isValidKeyOrValue: Bool {
        self.count > 0 && self.allSatisfy { $0.isLetter || $0.isDigit }
    }
    
    
    @inlinable
    var trimmed: Substring {
        if self.isEmpty { return self }
        
        var leftIndex = self.startIndex
        
        while self[leftIndex].isSpace {
            self.formIndex(after: &leftIndex)
            
            
            if leftIndex == self.endIndex {
                return self[leftIndex..<leftIndex]
            }
        }
        
        var rightIndex = self.index(before: self.endIndex)
        
        while rightIndex > leftIndex && self[rightIndex].isSpace {
            self.formIndex(before: &rightIndex)
        }
        
        return self[leftIndex..<(self.index(after: rightIndex))]
    }
    
    
    @inlinable
    func parseAsInterval() -> DispatchTimeInterval? {
        var iterator = self.makeIterator()
        
        guard let hoursUpper = iterator.next(), hoursUpper.isDigit else { return nil }
        guard let hoursLower = iterator.next(), hoursLower.isDigit else { return nil }
        guard iterator.next() == "h" && iterator.next() == "-" else { return nil }
        
        guard let minutesUpper = iterator.next(), Self._digitsZeroThroughFive.contains(minutesUpper) else { return nil }
        guard let minutesLower = iterator.next(), minutesLower.isDigit else { return nil }
        guard iterator.next() == "m" && iterator.next() == "-" else { return nil }
        
        guard let secondsUpper = iterator.next(), Self._digitsZeroThroughFive.contains(secondsUpper) else { return nil }
        guard let secondsLower = iterator.next(), secondsLower.isDigit else { return nil }
        guard iterator.next() == "s" && iterator.next() == nil else { return nil }
        
        
        let hours = Int((hoursUpper.asciiValue.unsafelyUnwrapped - Self._zeroASCIIValue) * 10 + (hoursLower.asciiValue.unsafelyUnwrapped - Self._zeroASCIIValue))
        let minutes = Int((minutesUpper.asciiValue.unsafelyUnwrapped - Self._zeroASCIIValue) * 10 + (minutesLower.asciiValue.unsafelyUnwrapped - Self._zeroASCIIValue))
        let seconds = Int((secondsUpper.asciiValue.unsafelyUnwrapped - Self._zeroASCIIValue) * 10 + (secondsLower.asciiValue.unsafelyUnwrapped - Self._zeroASCIIValue))
        
        return .seconds(hours * 3600 + minutes * 60 + seconds)
    }
}
