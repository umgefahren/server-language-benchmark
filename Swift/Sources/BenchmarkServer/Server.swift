//
//  Server.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 06.04.22.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

import SystemPackage


actor Server {
    #if canImport(Darwin)
    static private let domain = PF_INET
    #elseif canImport(Glibc)
    static private let domain = AF_INET
    #endif
    
    static private let invalidCommandString: CString = "invalid command\n"
    static private let notFoundString: CString = "not found\n"
    
    
    private let store: Store
    private let debug: Bool
    private let socketFD: Int32
    private var address: sockaddr_in
    private var addressSize: socklen_t
    
    init?(store: Store, debug: Bool) async {
        self.store = store
        self.debug = debug
        
        
        #if canImport(Darwin)
        self.socketFD = socket(Self.domain, SOCK_STREAM, 0)
        #elseif canImport(Glibc)
        self.socketFD = socket(Self.domain, Int32(SOCK_STREAM.rawValue), 0)
        #endif
        
        if self.socketFD == -1 {
            print("Could not create socket")
            return nil
        }
        
        self.address = sockaddr_in()
        self.addressSize = socklen_t(MemoryLayout.size(ofValue: self.address))
        
        
        var opt: Int32 = 1
        let optResult = setsockopt(self.socketFD, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout.size(ofValue: opt)))
        if optResult < 0 {
            close(self.socketFD)
            
            print("Could not set socket option")
            return nil
        }
        
        
        self.address.sin_family = sa_family_t(Self.domain)
        self.address.sin_addr.s_addr = in_addr_t(INADDR_ANY)
        self.address.sin_port = in_port_t(8080).bigEndian
        
        let bindServer = self.withPointerToAddress { addressPointer, addressSizePointer in
            bind(self.socketFD, addressPointer, addressSizePointer.pointee)
        }
        
        if bindServer < 0 {
            close(self.socketFD)
            
            print("Could not bind socket")
            return nil
        }
        
        
        if listen(self.socketFD, 1000) < 0 {
            close(self.socketFD)
            
            print("Could not start listening")
            return nil
        }
    }
    
    
    deinit {
        close(self.socketFD)
    }
    
    
    func run() async {
        await withThrowingTaskGroup(of: Void.self) { group in
            while true {
                let newSocketFD = self.withPointerToAddress { addressPointer, addressSizePointer in
                    accept(self.socketFD, addressPointer, addressSizePointer)
                }
                
                if newSocketFD == -1 {
                    let error = Errno(rawValue: errno)
                    if error == .resourceTemporarilyUnavailable || error == .wouldBlock {
                        continue
                    }
                    
                    print("Could not accept connection")
                    group.cancelAll()
                    return
                }
                
                group.addTask {
                    let handler = SocketHandler(withFileDescriptor: newSocketFD)
                    
                    while let line = await handler.nextLine()?.trimmed {
                        guard !line.isEmpty else { continue }
                        
                        if self.debug {
                            print("Received command:", String(bytes: line.rawBufferPointer!, encoding: .utf8)!)
                        }
                        
                        if let command = Command(fromString: line) {
                            switch command {
                            case let .get(key):
                                if let value = await self.store.getValue(forKey: key) {
                                    await handler.write(value)
                                } else {
                                    await handler.write(Self.notFoundString, appendingNewline: false)
                                }
                            case let .set(key, value):
                                if let value = await self.store.setValue(forKey: key, to: value) {
                                    await handler.write(value)
                                } else {
                                    await handler.write(Self.notFoundString, appendingNewline: false)
                                }
                            case let .delete(key):
                                if let value = await self.store.deleteValue(forKey: key) {
                                    await handler.write(value)
                                } else {
                                    await handler.write(Self.notFoundString, appendingNewline: false)
                                }
                            case .getCount:
                                await handler.write("\(await self.store.getCount)\n", appendingNewline: false)
                            case .setCount:
                                await handler.write("\(await self.store.setCount)\n", appendingNewline: false)
                            case .deleteCount:
                                await handler.write("\(await self.store.deleteCount)\n", appendingNewline: false)
                            }
                        } else {
                            await handler.write(Self.invalidCommandString, appendingNewline: false)
                        }
                    }
                    
                    close(newSocketFD)
                }
            }
        }
    }
    
    
    private func withPointerToAddress<R>(_ body: (UnsafeMutablePointer<sockaddr>, UnsafeMutablePointer<socklen_t>) throws -> R) rethrows -> R {
        try withUnsafeMutablePointer(to: &self.address) { addressPointer in
            try withUnsafeMutablePointer(to: &self.addressSize, { addressSizePointer in
                try body(UnsafeMutableRawPointer(addressPointer).assumingMemoryBound(to: sockaddr.self), addressSizePointer)
            })
        }
    }
}
