require "socket"

require "./dump.cr"
require "./hashmap.cr"
require "./record.cr"

module ServerBenchmark
  class Server
    @hashmap : ConcurrentHashMap(String, Record)
    @dump : Dump
    @getc = Atomic(UInt64).new 0
    @setc = Atomic(UInt64).new 0
    @delc = Atomic(UInt64).new 0

    def initialize
      @hashmap = ConcurrentHashMap(String, Record).new
      @dump = Dump.new(@hashmap)
    end

    def valid_key(key)
      key.each_char do |c|
        return false unless c.ascii_alphanumeric?
      end

      true
    end

    def parse_duration(s : String)
      # Format: 00h-00m-00s
      nil if s.size != 11

      hours = s[0, 2].to_i?
      mins = s[4, 2].to_i?
      secs = s[8, 2].to_i?

      format_invalid = s[2] != 'h' || s[3] != '-' || s[6] != 'm' || s[7] != '-' || s[10] != 's'
      if hours.nil? || mins.nil? || secs.nil? || format_invalid
        nil
      else
        Time::Span.new(hours: hours, minutes: mins, seconds: secs)
      end
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
      when "NEWDUMP"
        @dump.dump
        @dump.get
      when "GETDUMP"
        @dump.get
      when "DUMPINTERVAL"
        return "invalid command" if cmd.size < 2 || (dur = parse_duration(cmd[1])).nil?
        @dump.set_interval dur
        cmd[1]
      when "SETTTL"
        return "invalid command" if cmd.size < 3 || !(valid_key(cmd[1]) && valid_key(cmd[2])) || (dur = parse_duration(cmd[3])).nil?
        @setc.add 1
        ret = @hashmap[cmd[1]] = cmd[2]

        spawn do
          sleep dur
          @hashmap.delete cmd[1]
        end

        ret
      when "UPLOAD"
        "unimplemented"
      when "DOWNLOAD"
        "unimplemented"
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
        Fiber.yield
      end
    end

  end
end

server = ServerBenchmark::Server.new
server.start
