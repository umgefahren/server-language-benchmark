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

    def reset
      BlobStorage.reset
      @hashmap.reset
      @dump.reset
      @getc.set 0
      @setc.set 0
      @delc.set 0
    end

    def parse_duration?(s : String)
      # Format: 00h-00m-00s
      nil if s.size != 11

      hours = s[0, 2].to_i?
      mins = s[4, 2].to_i?
      secs = s[8, 2].to_i?

      format_invalid = s[2] != 'h' || s[3] != '-' || s[6] != 'm' || s[7] != '-' || s[10] != 's'
      if hours.nil? || mins.nil? || secs.nil? || format_invalid || mins >= 60 || secs >= 60
        nil
      else
        Time::Span.new(hours: hours, minutes: mins, seconds: secs)
      end
    end

    def handle_client(client)
      loop do 
        message = client.gets
        break if message.nil?

        cmd = message.strip.split

        handle_command(client, cmd)
      end
    end

    def handle_command(client, cmd)
      return "Invalid Command" if cmd.size == 0
      op = cmd[0]

      case op
      when "GET"
        return "invalid command" if cmd.size != 2 || !valid_key(cmd[1])
        @getc.add 1
        client.puts @hashmap[cmd[1]]
      when "SET"
        return "invalid command" if cmd.size != 3 || !(valid_key(cmd[1]) && valid_key(cmd[2]))
        @setc.add 1
        client.puts @hashmap[cmd[1]] = cmd[2]
      when "DEL"
        return "invalid command" if cmd.size != 2 || !valid_key(cmd[1])
        @delc.add 1
        client.puts @hashmap.delete cmd[1]
      when "GETC"
        return "invalid command" if cmd.size != 1
        client.puts @getc.get
      when "SETC"
        return "invalid command" if cmd.size != 1
        client.puts @getc.get
      when "DELC"
        return "invalid command" if cmd.size != 1
        client.puts @getc.get
      when "NEWDUMP"
        return "invalid command" if cmd.size != 1
        @dump.dump
        client.puts @dump.get
      when "GETDUMP"
        return "invalid command" if cmd.size != 1
        client.puts @dump.get
      when "DUMPINTERVAL"
        return "invalid command" if cmd.size != 2 || (dur = parse_duration?(cmd[1])).nil?
        @dump.set_interval dur
        client.puts "DONE"
      when "SETTTL"
        return "invalid command" if cmd.size != 3 || !(valid_key(cmd[1]) && valid_key(cmd[2])) || (dur = parse_duration?(cmd[3])).nil?
        @setc.add 1
        client.puts @hashmap[cmd[1]] = cmd[2]

        spawn do
          sleep dur
          @delc.add 1
          @hashmap.delete cmd[1]
        end
      when "UPLOAD"
        return "invalid command" if cmd.size != 3 || !valid_key(cmd[1]) || (size = cmd[2].to_u64?).nil?
        BlobStorage.upload client, cmd[1], size
      when "DOWNLOAD"
        return "invalid command" if cmd.size != 2 || !valid_key(cmd[1])
        BlobStorage.download client, cmd[1]
      when "REMOVE"
        return "invalid command" if cmd.size != 2 || !valid_key(cmd[1])
        BlobStorage.remove cmd[1]
        client.puts "DONE"
      when "RESET"
        return "invalid command" if cmd.size != 1
        reset
        client.puts "DONE"
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
