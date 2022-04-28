//
//  Server.swift
//  NIOBenchmarkServer
//
//  Created by Josef Zoller on 09.04.22.
//

import NIO


class Server {
    let group: MultiThreadedEventLoopGroup
    let bootstrap: ServerBootstrap
    
    
    init(store: Store) {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        self.bootstrap = ServerBootstrap(group: self.group)
            .serverChannelOption(ChannelOptions.backlog, value: 512)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandlers([BackPressureHandler(), CommandParser(), CommandHandler(store: store)])
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    deinit {
        try! self.group.syncShutdownGracefully()
    }
    
    
    func run() {
        let channel: Channel
        do {
            channel = try self.bootstrap.bind(host: "0.0.0.0", port: 8080).wait()
            
            print("Running server on:", channel.localAddress!)
        } catch {
            print("Could not bind server")
            return
        }
        
        do {
            try channel.closeFuture.wait()
        } catch {
            print(error.localizedDescription)
            return
        }
    }
}
