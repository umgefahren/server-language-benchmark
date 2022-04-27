//
//  FileHandler.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 14.04.22.
//

import Crypto
import Foundation
import SystemPackage


actor FileHandler {
    private static let doneString = "DONE\n"
    private static let errorString = "ERROR\n"
    static private let notFoundString: String = "not found\n"
    private static let okString = "OK\n"
    private static let readyString = "READY\n"
    
    
    private let storeURL: URL
    private let storePath: FilePath
    
    private var existingFiles: [String: (size: Int, hash: SHA512Digest)]
    
    
    init() async throws {
        self.storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("server-benchmark-swift", isDirectory: true)
        self.storePath = .init(self.storeURL.path)
        self.existingFiles = .init()
        
        print("Store:", self.storeURL.path)
        
        
        if FileManager.default.fileExists(atPath: self.storeURL.path) {
            try FileManager.default.removeItem(at: self.storeURL)
        }
        
        try FileManager.default.createDirectory(at: self.storeURL, withIntermediateDirectories: true)
    }
    
    deinit {
        try! FileManager.default.removeItem(at: self.storeURL)
    }
    
    
    func handleCommand(_ command: Command.File, withSocket socketHandler: SocketHandler) async {
        switch command {
        case let .upload(key, size):
            let fileName = String(key)
            let filePath = self.storePath.appending(fileName)
            
            self.existingFiles.removeValue(forKey: fileName)
            
            var hasher = SHA512()
            
            let fd = try! FileDescriptor.open(filePath, .writeOnly, options: .create, permissions: [.ownerReadWrite, .groupReadWrite, .otherRead])
            
            
            await socketHandler.write(Self.readyString, appendingNewline: false)
            
            
            var remainingBytes = size
            while remainingBytes > 0 {
                guard let buffer = await socketHandler.readBytes(maximumCount: remainingBytes), buffer.count > 0 else {
                    try! fd.close()
                    
                    filePath.withCString {
                        #if canImport(Darwin)
                        _ = Darwin.remove($0)
                        #elseif canImport(Glibc)
                        _ = Glibc.remove($0)
                        #endif
                    }
                    
                    return
                }
                
                hasher.update(bufferPointer: buffer)
                _ = try! fd.write(buffer)
                
                remainingBytes -= buffer.count
            }
            
            
            _ = try! fd.close()
            
            
            let digest = hasher.finalize()
            
            await socketHandler.write(digest.hexString)
            
            
            guard let response = await socketHandler.nextLine(), response == "OK" else {
                filePath.withCString {
                    #if canImport(Darwin)
                    _ = Darwin.remove($0)
                    #elseif canImport(Glibc)
                    _ = Glibc.remove($0)
                    #endif
                }
                
                return
            }
            
            
            self.existingFiles[fileName] = (size, digest)
        case let .download(key):
            let fileName = String(key)
            
            guard let (size, hash) = self.existingFiles[fileName] else {
                await socketHandler.write(Self.notFoundString, appendingNewline: false)
                return
            }
            
            let filePath = self.storePath.appending(fileName)
            
            await socketHandler.write("\(size)\n", appendingNewline: false)
            
            guard let response = await socketHandler.nextLine(), response == "READY" else {
                return
            }
            
            
            await socketHandler.writeContents(ofFile: filePath, size: size)
            
            
            guard let response = await socketHandler.nextLine(), response == hash.hexString else {
                await socketHandler.write(Self.errorString, appendingNewline: false)
                return
            }
            
            await socketHandler.write(Self.okString, appendingNewline: false)
        case let .delete(key):
            let fileName = String(key)
            
            guard self.existingFiles.removeValue(forKey: fileName) != nil else {
                await socketHandler.write(Self.notFoundString, appendingNewline: false)
                return
            }
            
            let filePath = self.storePath.appending(fileName)
            
            filePath.withCString {
                #if canImport(Darwin)
                _ = Darwin.remove($0)
                #elseif canImport(Glibc)
                _ = Glibc.remove($0)
                #endif
            }
            
            
            await socketHandler.write(Self.doneString, appendingNewline: false)
        }
    }
}
