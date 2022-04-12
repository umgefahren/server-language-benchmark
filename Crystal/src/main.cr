require "socket"

require "./hashmap.cr"
require "./record.cr"

module ServerBenchmark
  class Server
    @hashmap = ConcurrentHashMap(String, Record).new
    @getc = Atomic(UInt64).new 0
    @setc = Atomic(UInt64).new 0
    @delc = Atomic(UInt64).new 0

    def valid_key(key)
      key.each_char do |c|
        return false unless c.ascii_alphanumeric?
      end

      true
    end

    def handle_client(client)
      loop do 
        message = client.gets
        break if message.nil?

        cmd = message.split

        client.puts handle_command(cmd)
      end
    end

    def handle_command(cmd)
      return "Invalid Command" if cmd.size == 0
      op = cmd[0]

      case op
      when "GET"
        return "invalid command" if cmd.size < 2 || !valid_key(cmd[1])
        @getc.add 1
        @hashmap[cmd[1]]
      when "SET"
        return "invalid command" if cmd.size < 3 || !(valid_key(cmd[1]) && valid_key(cmd[2]))
        @setc.add 1
        @hashmap[cmd[1]] = cmd[2]
      when "DEL"
        return "invalid command" if cmd.size < 2 || !valid_key(cmd[1])
        @delc.add 1
        @hashmap.delete cmd[1]
      when "GETC"
        @getc.get
      when "SETC"
        @getc.get
      when "DELC"
        @getc.get
      else
        "invalid command"
      end
    end

    def start
      puts "Starting server"
      server = TCPServer.new(8080)
      loop do
        if client = server.accept?
          spawn handle_client(client)
        else
          break
        end
      end
    end

  end
end

server = ServerBenchmark::Server.new
server.start
