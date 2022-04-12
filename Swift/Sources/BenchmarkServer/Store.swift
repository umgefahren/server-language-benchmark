//
//  Store.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 06.04.22.
//


actor Store {
    private var dictionary = [CStringSlice: CStringSlice]()
    private(set) var getCount = 0
    private(set) var setCount = 0
    private(set) var deleteCount = 0
    
    
    func getValue(forKey key: CStringSlice) -> CStringSlice? {
        self.getCount += 1
        
        return self.dictionary[key]
    }
    
    func setValue(forKey key: CStringSlice, to value: CStringSlice) -> CStringSlice? {
        self.setCount += 1
        
        let previous = self.dictionary[key]
        if previous != nil {
            self.dictionary[key] = value
            
            key.deallocate()
        } else {
            self.dictionary[key] = value
        }
        
        return previous
    }
    
    func deleteValue(forKey key: CStringSlice) -> CStringSlice? {
        self.deleteCount += 1
        
        let previous: CStringSlice?
        if let index = self.dictionary.index(forKey: key) {
            let oldKey: CStringSlice
            (oldKey, previous) = self.dictionary[index]
            
            self.dictionary.remove(at: index)
            
            oldKey.deallocate()
        } else {
            previous = nil
        }
        
        return previous
    }
}
