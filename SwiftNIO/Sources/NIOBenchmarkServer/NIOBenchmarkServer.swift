//
//  NIOBenchmarkServer.swift
//  NIOBenchmarkServer
//
//  Created by Josef Zoller on 09.04.22.
//

import Foundation


@main
struct NIOBenchmarkServer {
    static func main() {
        let store = Store()
        
        let server = Server(store: store)
        
        
        print("Starting server listening on 127.0.0.1:8080")
        
        server.run()
    }
}
