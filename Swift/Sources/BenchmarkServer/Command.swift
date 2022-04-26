//
//  Command.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 06.04.22.
//

import Dispatch


enum Command {
    case get(key: Substring)
    case set(key: Substring, value: Substring)
    case delete(key: Substring)
    case getCount
    case setCount
    case deleteCount
    case newDump
    case getDump
    case dumpInterval(interval: DispatchTimeInterval)
    case setTTL(key: Substring, value: Substring, duration: DispatchTimeInterval)
    
    
    init?(fromString string: Substring) {
        let words = string.split(separator: " ", omittingEmptySubsequences: false)
        
        guard let commandString = words.first else { return nil }
        
        
        switch commandString {
        case "GET":
            guard words.count == 2 else { return nil }
            
            let key = words[1]
            
            guard key.isValidKeyOrValue else { return nil }
            
            self = .get(key: key)
        case "SET":
            guard words.count == 3 else { return nil }
            
            let key = words[1]
            let value = words[2]
            
            guard key.isValidKeyOrValue && value.isValidKeyOrValue else { return nil }
            
            self = .set(key: key, value: value)
        case "DEL":
            guard words.count == 2 else { return nil }
            
            let key = words[1]
            
            guard key.isValidKeyOrValue else { return nil }
            
            self = .delete(key: key)
        case "GETC":
            guard words.count == 1 else { return nil }
            
            self = .getCount
        case "SETC":
            guard words.count == 1 else { return nil }
            
            self = .setCount
        case "DELC":
            guard words.count == 1 else { return nil }
            
            self = .deleteCount
        case "NEWDUMP":
            guard words.count == 1 else { return nil }
            
            self = .newDump
        case "GETDUMP":
            guard words.count == 1 else { return nil }
            
            self = .getDump
        case "DUMPINTERVAL":
            guard words.count == 2 else { return nil }
            
            let intervalString = words[1]
            
            guard let interval = intervalString.parseAsInterval() else { return nil }
            
            self = .dumpInterval(interval: interval)
        case "SETTTL":
            guard words.count == 4 else { return nil }
            
            let key = words[1]
            let value = words[2]
            let durationString = words[3]
            
            guard let duration = durationString.parseAsInterval(), key.isValidKeyOrValue, value.isValidKeyOrValue else { return nil }
            
            self = .setTTL(key: key, value: value, duration: duration)
        default:
            return nil
        }
    }
}
