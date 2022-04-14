//
//  Store.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 06.04.22.
//

import Foundation


actor Store {
    private static let dateFormatter: DateFormatter = MicrosecondPrecisionDateFormatter()
    
    private var dictionary = [CString: (value: CString, date: Date)]()
    private(set) var getCount = 0
    private(set) var setCount = 0
    private(set) var deleteCount = 0
    
    private var recurringDumpTask: Task<Void, Error>?
    private var recurringDumpInterval = DispatchTimeInterval.seconds(10)
    private var lastDumpTime: DispatchTime?
    
    private var snapshot: [CString: (value: CString, date: Date)]?
    
    
    func getValue(forKey key: CString) -> CString? {
        self.getCount += 1
        
        return self.dictionary[key]?.value
    }
    
    func setValue(forKey key: CString, to value: CString) -> CString? {
        self.setCount += 1
        
        let previous = self.dictionary[key]?.value
        if previous != nil {
            self.dictionary[key] = (value.copy, .init())
        } else {
            self.dictionary[key.copy] = (value.copy, .init())
        }
        
        return previous
    }
    
    func deleteValue(forKey key: CString) -> CString? {
        self.deleteCount += 1
        
        return self.dictionary.removeValue(forKey: key)?.value
    }
    
    
    @discardableResult
    func createSnapshot() -> [CString: (value: CString, date: Date)] {
        self.snapshot = self.dictionary
        
        return self.dictionary
    }
    
    
    func setValue(forKey key: CString, to value: CString, deleteAfter timeout: DispatchTimeInterval) -> CString? {
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
    
    
    nonisolated func dump(to socketHandler: SocketHandler) async {
        let dictionary: [CString: (value: CString, date: Date)]
        if let snapshot = await self.snapshot {
            dictionary = snapshot
        } else {
            dictionary = await self.createSnapshot()
        }
        
        await socketHandler.write("[", appendingNewline: false)
        
        for (index, (key, (value, timestamp))) in dictionary.enumerated() {
            await socketHandler.write(#"{"key":""#, appendingNewline: false)
            await socketHandler.write(key, appendingNewline: false)
            await socketHandler.write(#"","associated_value":{"value":""#, appendingNewline: false)
            await socketHandler.write(value, appendingNewline: false)
            await socketHandler.write(#"","timestamp":""#, appendingNewline: false)
            await socketHandler.write(Self.dateFormatter.string(from: timestamp), appendingNewline: false)
            if index == dictionary.count - 1 {
                await socketHandler.write(#""}}"#, appendingNewline: false)
            } else {
                await socketHandler.write(#""}},"#)
            }
        }
        
        await socketHandler.write("]\n", appendingNewline: false)
    }
}
