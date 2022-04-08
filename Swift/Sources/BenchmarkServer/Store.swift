//
//  Store.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 06.04.22.
//


actor Store {
    private var dictionary = [Substring: Substring]()
    private(set) var getCount = 0
    private(set) var setCount = 0
    private(set) var deleteCount = 0
    
    
    func getValue(forKey key: Substring) -> Substring? {
        self.getCount += 1
        
        return self.dictionary[key]
    }
    
    func setValue(forKey key: Substring, to value: Substring) -> Substring? {
        self.setCount += 1
        
        let previous = self.dictionary[key]
        
        self.dictionary[key] = value
        
        return previous
    }
    
    func deleteValue(forKey key: Substring) -> Substring? {
        self.deleteCount += 1
        
        let previous = self.dictionary[key]
        
        self.dictionary[key] = nil
        
        return previous
    }
}
