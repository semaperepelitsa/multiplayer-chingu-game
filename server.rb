require "socket"
require "set"

server = TCPServer.open("localhost", 4466)

$clients = Set.new

trap(:INT) do
  puts "Shutting down"
  $clients.each do |client|
    client.close
  end
  server.close
  exit
end

loop {
  puts "Listening for a client"
  Thread.start(server.accept) do |client|
    puts "Connected to a client"
    $clients << client
    loop {
      message = client.gets
      break if message.nil?
      $clients.each do |other|
        other.puts message unless other == client
      end
      puts "[#{Time.now}] #{message}"
    }
    puts "Closed connection"
    $clients.delete(client)
  end
}
