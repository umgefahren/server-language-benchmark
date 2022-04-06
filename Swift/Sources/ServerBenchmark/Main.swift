//
//  Main.swift
//  ServerBenchmark
//
//  Created by Josef Zoller on 07.04.22.
//


@main
enum Main {
    static func main() async {
        let store = Store()
        
        guard let server = await Server(store: store) else {
            return
        }
        
        
        print("Running server")
        
        
        await server.run()
    }
}
