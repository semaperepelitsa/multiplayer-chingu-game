require "socket"

server = TCPServer.open("localhost", 4467)
client = server.accept
10.times do
  client.puts "Hello #{Time.now}"
  sleep rand(3)
end
