require "json"

class Node < Chingu::BasicGameObject
  traits :timer
  RECONNECT_AFTER = 500
  SEND_DELAY = 20

  def initialize(controlled)
    super()
    @buffer = ""
    connect
    @controlled = controlled
    @remote = {}
  end

  def update
    super
    
  end

  def connection_lost?
    @socket.nil?
  end

  def connected?
    @socket
  end

  private

  def connect
    return if @socket
    @socket = TCPSocket.open('localhost', 4466)
  rescue Errno::ECONNREFUSED
    $logger.info "Retrying the connection"
    after(RECONNECT_AFTER){ connect }
  else
    $logger.info "Connected"
    every(20, name: :updates) do
      send_updates
      receive_updates
    end
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
    @remote.each{ |id, object| object.destroy }
    destroy
  end

  def send_updates
    @controlled.each do |object|
      send_data(object)
    end
  end

  def send_data(object)
    @socket.puts JSON.dump([object.id.to_s] << object.attributes) if connected?
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
    id, attributes = JSON.parse(data)
    player = @remote[id] ||= BasicPlayer.create(id: id)
    player.attributes = attributes
  end
end
