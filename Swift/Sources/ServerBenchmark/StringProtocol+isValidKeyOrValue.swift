//
//  StringProtocol+isValidKeyOrValue.swift
//  ServerBenchmark
//
//  Created by Josef Zoller on 07.04.22.
//

import Foundation


fileprivate let disallowedCharacters: CharacterSet = {
    var characterSet = CharacterSet(charactersIn: "a"..."z")
    characterSet.formUnion(.init(charactersIn: "A"..."Z"))
    characterSet.formUnion(.init(charactersIn: "0"..."9"))
    
    return characterSet.inverted
}()


extension StringProtocol {
    var isValidKeyOrValue: Bool {
        self.count > 0 && self.rangeOfCharacter(from: disallowedCharacters) == nil
    }
}
