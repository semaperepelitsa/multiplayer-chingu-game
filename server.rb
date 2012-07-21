require "socket"
require "set"

server = TCPServer.open("localhost", 4466)

trap(:INT) do
  puts "Shutting down"
  exit
end

def broadcast(message, from_id, all_clients)
  all_clients.each do |id, other|
    other.puts message unless id == from_id
  end
end

class Client
end

clients = {}
loop {
  Thread.start(server.accept) do |client|
    puts "Connecting to a client"
    id = client.gets
    puts "Connected to #{id}"
    clients[id] = client
    loop {
      message = client.gets
      break if message.nil?
      broadcast(message, id, clients)
    }
    puts "Closed connection"
    clients.delete(id)
    broadcast(id, nil, clients)
  end
}
