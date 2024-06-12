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
        
        
        server.run()
    }
}
