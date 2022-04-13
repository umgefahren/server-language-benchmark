//
//  Store.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 06.04.22.
//


actor Store {
    private var dictionary = [CString: CString]()
    private(set) var getCount = 0
    private(set) var setCount = 0
    private(set) var deleteCount = 0
    
    
    func getValue(forKey key: CString) -> CString? {
        self.getCount += 1
        
        return self.dictionary[key]
    }
    
    func setValue(forKey key: CString, to value: CString) -> CString? {
        self.setCount += 1
        
        let previous = self.dictionary[key]
        if previous != nil {
            self.dictionary[key] = value.copy
        } else {
            self.dictionary[key.copy] = value.copy
        }
        
        return previous
    }
    
    func deleteValue(forKey key: CString) -> CString? {
        self.deleteCount += 1
        
        return self.dictionary.removeValue(forKey: key)
    }
}
