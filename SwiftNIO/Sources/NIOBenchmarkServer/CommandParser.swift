//
//  CommandParser.swift
//  NIOBenchmarkServer
//
//  Created by Josef Zoller on 09.04.22.
//

import NIO


final class CommandParser: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = [Command?]
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let inBuffer = self.unwrapInboundIn(data)
        
        guard let string = inBuffer.getString(at: 0, length: inBuffer.readableBytes), !string.isEmpty else { return }
        
        print("Received command:", string)
        
        let commands = string.split(separator: "\n").map({
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }).filter({ !$0.isEmpty }).map(Command.init(fromString:))
        
        context.fireChannelRead(self.wrapInboundOut(commands))
    }
}
