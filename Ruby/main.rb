require 'socket'
require './command.rb'
require './store.rb'
require './handler.rb'

class Main
  include Parsing

  def run
    command_queue = Queue.new

    Thread.new do
      store_process command_queue
    end

    server = TCPServer.new 8080
    loop do
      client = server.accept
      Thread.new do
        h = Handler.new client, command_queue
        h.execute
      end
    end
  end
end

Main.new.run
