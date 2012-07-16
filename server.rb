require "socket"
require "set"

server = TCPServer.open("localhost", 4466)

trap(:INT) do
  puts "Shutting down"
  exit
end

def broadcast(message, from_client, all_clients)
  all_clients.each do |other|
    other.puts message unless other == from_client
  end
end

clients = Set.new
loop {
  Thread.start(server.accept) do |client|
    puts "Connected to a client"
    clients << client
    loop {
      message = client.gets
      break if message.nil?
      broadcast(message, client, clients)
      puts "[#{Time.now}] #{message}"
    }
    puts "Closed connection"
    clients.delete(client)
  end
}
