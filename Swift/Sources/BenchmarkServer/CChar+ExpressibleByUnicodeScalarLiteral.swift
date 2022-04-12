//
//  CChar+ExpressibleByUnicodeScalarLiteral.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 12.04.22.
//

extension CChar: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral scalar: Unicode.Scalar) {
        precondition(scalar.isASCII)
        
        self = CChar(scalar.value)
    }
    
    
    var isSpace: Bool {
        self == " " || self == "\t"
    }
}
