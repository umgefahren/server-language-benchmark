//
//  CChar+ExpressibleByUnicodeScalarLiteral.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 12.04.22.
//

extension CChar: ExpressibleByUnicodeScalarLiteral {
    @usableFromInline
    internal static let _lowercaseLetters: ClosedRange<CChar> = "a"..."z"
    @usableFromInline
    internal static let _uppercaseLetters: ClosedRange<CChar> = "A"..."Z"
    @usableFromInline
    internal static let _digits: ClosedRange<CChar> = "0"..."9"
    
    
    public init(unicodeScalarLiteral scalar: Unicode.Scalar) {
        precondition(scalar.isASCII)
        
        self = CChar(scalar.value)
    }
    
    
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
