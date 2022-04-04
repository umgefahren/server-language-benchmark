require './record.rb'

class Store
  @content = {}
  @get_counter = 0
  @set_counter = 0
  @del_counter = 0

  def initialize
    @get_counter = 0
    @set_counter = 0
    @del_counter = 0
    @content = {}
  end

  def set(key, value)
    record = Record.new key, value
    @content[key] = record
    @set_counter += 1
  end

  def get(key)
    @get_counter += 1
    @content[key]
  end

  def del(key)
    @del_counter += 1
    @content.delete key
  end

  def get_counter
    @get_counter
  end

  def set_counter
    @set_counter
  end

  def del_counter
    @del_counter
  end

  def all
    @content.clone
  end
end

class StoreCommand
  @type
  @key
  @value
  @duration
  @back_channel

  def initialize(type, back_channel = nil, key = nil, value = nil, duration = nil)
    @type = type
    @back_channel = back_channel
    @duration = duration
    @key = key
    @value = value
  end

  def execute(store)
    case @type
    when :get
      result = store.get @key
      @back_channel << result
    when :set
      result = store.get @key
      store.set @key, @value
      @back_channel << result
    when :del
      result = store.del @key
      @back_channel << result
    when :get_counter
      @back_channel << store.get_counter
    when :set_counter
      @back_channel << store.set_counter
    when :del_counter
      @back_channel << store.del_counter
    else
      @back_channel << "invalid command"
      return
    end
  end
end


def store_process(command_queue)
  store = Store.new
  loop do
    command = command_queue.pop
    command.execute store
  end
end