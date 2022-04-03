require 'socket'
require './command.rb'

class Main
  include Parsing

  def run
    string = 'GET key'


    command = parse_command string
    puts command
  end
end

Main.new.run
