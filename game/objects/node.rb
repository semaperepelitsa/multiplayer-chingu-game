require "json"

module LoggedSocket
  def puts(message)
    $logger.info "sending #{message.inspect}"
    super
  end
end

class Node < Chingu::BasicGameObject
  traits :timer
  RECONNECT_AFTER = 500
  SEND_DELAY = 20

  attr_reader :id

  def initialize(controlled)
    super()
    @id = controlled.first.id
    @controlled = controlled
    @buffer = ""
    @remote = {}

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
    @remote.each{ |id, object| object.destroy }
    destroy
  end

  def send_id
    @socket.puts JSON.dump([id.to_s])
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
    if attributes
      player = @remote[id] ||= Player.create(id: id, remote: true)
      player.attributes = attributes
    else
      $logger.info "Deleting #{id.inspect}"
      @remote.delete(id).destroy
    end
  end
end
