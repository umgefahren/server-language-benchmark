require './command.rb'
require './store.rb'

class Handler
  include Parsing

  @socket
  @command_queue

  def initialize(socket, command_queue)
    @socket = socket
    @command_queue = command_queue
  end

  def execute
    line = @socket.gets
    command = parse_command line
    back_queue = Queue.new
    store_command = StoreCommand.new(command.type, back_queue, command.key, command.value, command.time)
    @command_queue << store_command
    response = back_queue.pop
    if response == nil
      @socket.puts "not found"
    elsif response.is_a? Record
      @socket.puts response.value
    elsif response.is_a? Integer
      @socket.puts response
    end
    @socket.close
  end
end