//
//  Store.swift
//  ServerBenchmark
//
//  Created by Josef Zoller on 09.04.22.
//

import Foundation


actor Store {
    private static let dateFormatter: DateFormatter = MicrosecondPrecisionDateFormatter()
    
    private var dictionary = [Substring: (value: Substring, date: Date)]()
    private(set) var getCount = 0
    private(set) var setCount = 0
    private(set) var deleteCount = 0
    
    private var recurringDumpTask: Task<Void, Error>?
    private var recurringDumpInterval = DispatchTimeInterval.seconds(10)
    private var lastDumpTime: DispatchTime?
    
    private var snapshot: [Substring: (value: Substring, date: Date)]?
    
    
    func getValue(forKey key: Substring) -> Substring? {
        self.getCount += 1
        
        return self.dictionary[key]?.value
    }
    
    func setValue(forKey key: Substring, to value: Substring) -> Substring? {
        self.setCount += 1
        
        let previous = self.dictionary[key]?.value
        if previous != nil {
            self.dictionary[key] = (value.copy, .init())
        } else {
            self.dictionary[key.copy] = (value.copy, .init())
        }
        
        return previous
    }
    
    func deleteValue(forKey key: Substring) -> Substring? {
        self.deleteCount += 1
        
        return self.dictionary.removeValue(forKey: key)?.value
    }
    
    
    @discardableResult
    func createSnapshot() -> [Substring: (value: Substring, date: Date)] {
        print("Created snapshot")
        
        self.snapshot = self.dictionary
        
        return self.dictionary
    }
    
    
    func setValue(forKey key: Substring, to value: Substring, deleteAfter timeout: DispatchTimeInterval) -> Substring? {
        let key = key.copy
        
        let returnValue = self.setValue(forKey: key, to: value)
        
        Task.detached {
            let now = DispatchTime.now()
            let timeout = now.advanced(by: timeout).uptimeNanoseconds
            
            try await Task.sleep(nanoseconds: timeout - now.uptimeNanoseconds)
            
            _ = await self.deleteValue(forKey: key)
        }
        
        return returnValue
    }
    
    
    func runRecurringDumperTask() async {
        repeat {
            self.recurringDumpTask = Task.detached {
                let (lastDumpTime, dumpInterval) = await self.lastDumpTimeAndDumpInterval
                let now = DispatchTime.now()
                
                let timeout = (lastDumpTime ?? now).advanced(by: dumpInterval).uptimeNanoseconds
                
                try await Task.sleep(nanoseconds: timeout - now.uptimeNanoseconds)
                
                await self.setLastDumpTime(.now())
                
                await self.createSnapshot()
            }
            
            do {
                try await self.recurringDumpTask?.value
            } catch is CancellationError {
                self.lastDumpTime = nil
            } catch {
                fatalError("Unreachable")
            }
        } while true
    }
    
    func updateDumpInterval(_ newValue: DispatchTimeInterval) {
        self.recurringDumpInterval = newValue
        self.recurringDumpTask?.cancel()
    }
    
    
    private var lastDumpTimeAndDumpInterval: (DispatchTime?, DispatchTimeInterval) {
        (self.lastDumpTime, self.recurringDumpInterval)
    }
    
    private func setLastDumpTime(_ newValue: DispatchTime) {
        self.lastDumpTime = newValue
    }
    
    
    nonisolated func getDump() async -> String {
        let dictionary: [Substring: (value: Substring, date: Date)]
        if let snapshot = await self.snapshot {
            dictionary = snapshot
        } else {
            dictionary = await self.createSnapshot()
        }
        
        var string = "["
        
        for (index, (key, (value, date))) in dictionary.enumerated() {
            let timestamp = Self.dateFormatter.string(from: date)
            
            string += #"{"key":"\#(key)","associated_value":{"value":"\#(value)","timestamp":"\#(timestamp)"}}"#
            
            if index != dictionary.count - 1 {
                string += ",\n"
            }
        }
        
        return string + "]"
    }
}
