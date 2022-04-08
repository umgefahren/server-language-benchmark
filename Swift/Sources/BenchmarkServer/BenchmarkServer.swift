//
//  BenchmarkServer.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 07.04.22.
//

import ArgumentParser
import Foundation


#if swift(<5.6)
@main struct Main: AsyncMainProtocol {
    typealias Command = BenchmarkServer
}


struct BenchmarkServer: AsyncParsableCommand {
    @Argument(help: "Print received commands")
    var debug = false
    
    mutating func run() async {
        let store = Store()
        
        guard let server = await Server(store: store, debug: self.debug) else {
            return
        }
        
        
        signal(SIGINT, SIG_IGN)
        
        
        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: DispatchQueue.main)
        
        
        sigintSource.setEventHandler {
            #if canImport(Darwin)
            Darwin.exit(EXIT_FAILURE)
            #elseif canImport(Glibc)
            Glibc.exit(EXIT_FAILURE)
            #else
            #error("OS not supported")
            #endif
        }
        
        sigintSource.resume()
        
        
        print("Running server")
        
        
        await server.run()
    }
}

#else

@main
struct BenchmarkServer: AsyncParsableCommand {
    @Argument(help: "Print received commands")
    var debug = false
    
    mutating func run() async {
        let store = Store()
        
        guard let server = await Server(store: store, debug: self.debug) else {
            return
        }
        
        
        signal(SIGINT, SIG_IGN)
        
        
        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: DispatchQueue.main)
        
        
        sigintSource.setEventHandler {
            #if canImport(Darwin)
            Darwin.exit(EXIT_FAILURE)
            #elseif canImport(Glibc)
            Glibc.exit(EXIT_FAILURE)
            #else
            #error("OS not supported")
            #endif
        }
        
        sigintSource.resume()
        
        
        print("Running server")
        
        
        await server.run()
    }
}
#endif
