//
//  Character+Helpers.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 12.04.22.
//

extension Character {
    @usableFromInline
    internal static let _lowercaseLetters: ClosedRange<Character> = "a"..."z"
    @usableFromInline
    internal static let _uppercaseLetters: ClosedRange<Character> = "A"..."Z"
    @usableFromInline
    internal static let _digits: ClosedRange<Character> = "0"..."9"
    
    
    @inlinable
    public var isSpace: Bool {
        self == " " || self == "\t"
    }
    
    @inlinable
    public var isLowercaseLetter: Bool {
        Self._lowercaseLetters.contains(self)
    }
    
    @inlinable
    public var isUppercaseLetter: Bool {
        Self._uppercaseLetters.contains(self)
    }
    
    @inlinable
    public var isLetter: Bool {
        Self._lowercaseLetters.contains(self) || Self._uppercaseLetters.contains(self)
    }
    
    @inlinable
    public var isDigit: Bool {
        Self._digits.contains(self)
    }
}
