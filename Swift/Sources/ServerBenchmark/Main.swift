//
//  Main.swift
//  ServerBenchmark
//
//  Created by Josef Zoller on 07.04.22.
//

import Foundation


@main
enum Main {
    static func main() async {
        let store = Store()
        
        guard let server = await Server(store: store) else {
            return
        }
        
        
        signal(SIGINT, SIG_IGN)
        
        
        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: DispatchQueue.main)
        
        
        sigintSource.setEventHandler {
            exit(EXIT_FAILURE)
        }
        
        sigintSource.resume()
        
        
        print("Running server")
        
        
        await server.run()
    }
}
