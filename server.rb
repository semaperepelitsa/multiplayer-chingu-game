require "socket"
require "set"
require "logger"

host, port = "0.0.0.0", ENV['PORT'] || 4466
p ENV
server = TCPServer.open(host, port)
logger = Logger.new($stdout)

trap(:INT) do
  logger.info "Shutting down"
  exit
end

logger.info "Listening on #{host}:#{port}"

def broadcast(message, from_id, all_clients)
  all_clients.each do |id, other|
    other.puts message unless id == from_id
  end
end

clients = {}
loop {
  Thread.start(server.accept) do |client|
    logger.info "Connecting to a client"
    id = client.gets.chomp
    logger.info "Connected to #{id}"
    clients[id] = client
    loop {
      message = client.gets
      break if message.nil?
      broadcast(message, id, clients)
    }
    logger.info "Disconnected from #{id}"
    clients.delete(id)
    broadcast(id, nil, clients)
  end
}
