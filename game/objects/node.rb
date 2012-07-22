require "json"

module LoggedSocket
  def puts(message)
    $logger.info "sending #{message.inspect}"
    super
  end
end

class Node < Chingu::BasicGameObject
  class GameObjectList
    include Identity

    def self.[](id)
      i = new
      i.id = id
      i
    end

    def initialize(game_objects = [])
      @game_objects = game_objects
      setup_id
    end

    def <<(obj)
      @game_objects << obj
    end

    def attributes
      [id, @game_objects.map(&:attributes)]
    end

    def update(data)
      data.each_with_index do |attributes, i|
        @game_objects[i] ||= load_object(attributes)
        @game_objects[i].attributes = attributes
      end
    end

    def destroy_all
      @game_objects.each(&:destroy)
    end

    private

    def load_object(attributes)
      $logger.info "Object #{attributes} loaded"
      type = attributes.pop
      Object.const_get(type).create(remote: true)
    end
  end

  traits :timer
  RECONNECT_AFTER = 500
  SEND_DELAY = 20

  attr_reader :controlled

  def initialize(controlled)
    super()
    @controlled = GameObjectList.new(controlled)
    @buffer = ""
    @remote = Hash.new do |hash, id|
      hash[id] = GameObjectList[id]
    end

    @host, @port = ARGV
    @host ||= 'localhost'
    @port ||= 4466

    connect
  end

  def connection_lost?
    @socket.nil?
  end

  def connected?
    @socket
  end

  def update
    super
    send_updates
    receive_updates
  end

  private

  def connect
    return if @socket
    @socket = TCPSocket.open(@host, @port)#.extend(LoggedSocket)
  rescue Errno::ECONNREFUSED
    $logger.info "Retrying the connection"
    after(RECONNECT_AFTER){ connect }
  else
    send_id
    $logger.info "Connected"
  end

  def connection_lost
    return if connection_lost?
    stop_timer(:updates) # doesn't work?
    @socket = nil
    $logger.info "Connection to the server lost"
    connect
  end

  def connection_totally_lost
    $logger.info "Connection to the server totally lost"
    @remote.each{ |id, objects| objects.destroy_all }
    destroy
  end

  def send_id
    @socket.puts JSON.dump(@controlled.id)
  end

  def send_updates
    @socket.puts JSON.dump(@controlled.attributes) if connected?
  rescue Errno::EPIPE
    connection_lost
  end

  def receive_updates
    @buffer << @socket.read_nonblock(1000) if @socket
  rescue Errno::EAGAIN
  rescue Errno::ECONNRESET, EOFError
    connection_lost
  else
    while message = @buffer.slice!(/.*\n/)
      receive_data(message)
    end
  end

  def receive_data(data)
    id, objects = JSON.parse(data)
    if objects
      @remote[id].update(objects)
    else
      $logger.info "Deleting #{id.inspect}"
      @remote.delete(id).destroy_all
    end
  end
end
